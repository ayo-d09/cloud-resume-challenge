#!/bin/bash
set -euo pipefail

# Config
BUCKET_NAME="ayo-portfolio-site-12345"
AWS_REGION="us-east-1"
WEBSITE_DIR="./website"
TERRAFORM_DIR="./terraform"

# Checks
echo "Checking requirements..."
command -v aws       &>/dev/null || { echo "AWS CLI not installed"; exit 1; }
command -v terraform &>/dev/null || { echo "Terraform not installed"; exit 1; }
aws sts get-caller-identity &>/dev/null || { echo "AWS credentials not configured. Run: aws configure"; exit 1; }
[[ -f "$WEBSITE_DIR/index.html" ]] || { echo "index.html not found in $WEBSITE_DIR"; exit 1; }
echo "All checks passed."

# Get CloudFront Distribution ID
echo "Getting CloudFront Distribution ID..."
cd "$TERRAFORM_DIR"
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
echo "Distribution ID: $DISTRIBUTION_ID"
cd -

# Upload files to S3
aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_NAME" --delete --exclude "*.DS_Store"

aws s3api head-object \
  --bucket "$BUCKET_NAME" \
  --key index.html >/dev/null

echo "✓ index.html uploaded successfully"
# Force fresh index.html on every request
aws s3 cp "$WEBSITE_DIR/index.html" "s3://$BUCKET_NAME/index.html" \
  --content-type "text/html" \
  --cache-control "no-cache" \
  --metadata-directive REPLACE
echo "Upload complete."

# Clear CloudFront Cache
echo "Clearing CloudFront cache..."
INVALIDATION_ID=$(
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query "Invalidation.Id" \
    --output text
)

echo "Waiting for cache to clear..."
aws cloudfront wait invalidation-completed \
  --distribution-id "$DISTRIBUTION_ID" \
  --id "$INVALIDATION_ID"
echo "Cache cleared."

# Done
CLOUDFRONT_URL=$(
  aws cloudfront get-distribution \
    --id "$DISTRIBUTION_ID" \
    --query "Distribution.DomainName" \
    --output text
)
echo ""
echo "Deployment complete!"
echo "Live URL: https://$CLOUDFRONT_URL"  
