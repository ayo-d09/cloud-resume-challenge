provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "portfolio" {
  provider    = aws.us-east-1
  domain      = "ayomideobadina.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name
}


resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "portfolio-oac"
  description                       = "Access S3 securely"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["ayomideobadina.com", "www.ayomideobadina.com"]
  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.portfolio.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.portfolio.id

  depends_on = [
    aws_cloudfront_distribution.cdn
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}


resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 3600
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    DistributionId = aws_cloudfront_distribution.cdn.id
    Region         = "Global"
  }

  alarm_description = "Alert when CloudFront has high 4xx errors"
  alarm_actions     = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name = "cloudfront-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "obadina111@gmail.com"
}
