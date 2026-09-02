

A personal portfolio and resume site hosted on AWS, extended into a full implementation of the Cloud Resume Challenge: a static frontend served over a secure CDN, backed by a serverless visitor-counter API, all provisioned with Terraform and deployed through two independent CI/CD pipelines.
---

## Demo

https://ayomideobadina.com

---

## Architecture

The portfolio is deployed using a secure, CDN-backed architecture designed for high availability, low latency, and best-practice cloud security.

FRONTEND 
```
                        ┌─────────────┐
                        │ Cloudflare  │  - DNS Management
                        └──────┬──────┘
                               │
                        ┌──────v──────┐
                        │ CloudFront  │  - CDN / HTTPS 
                        └──────┬──────┘
                               │
                        ┌──────v──────┐
                        │   S3 Bucket │  - Private Origin
                        │  (Static)   │
                        └─────────────┘
```

BACKEND - Visitor counter
```
   Browser
      │
      │  GET /count
      v
┌─────────────┐
│ API Gateway │  - HTTP API
└──────┬──────┘
       │
       v
┌─────────────┐
│   Lambda    │  - Python, atomic increment
└──────┬──────┘
       │
       v
┌─────────────┐
│  DynamoDB   │  - visitor-count table
└─────────────┘
```
---

## AWS Services Used

**S3 — Static website files (HTML, CSS, JS)**
**CloudFront — Global CDN, HTTPS enforcement** 
**ACM — SSL/TLS certificate provisioning**
**API Gateway (HTTP API) — Public GET /count endpoint**
**Lambda (Python 3.12) — Atomic visitor-count increment via boto3**
**DynamoDB — Single-table, single-item visitor counter (on-demand billing)** 
**IAM — Least-privilege roles for Lambda and CI/CD (OIDC, no static keys)**
**CloudWatch — Monitoring and alerting (CloudFront 4xx alarm, Lambda logs)**
**SNS — Alarm notifications**
**Cloudflare is used for DNS instead of Route 53.**



## Features

- Secure static hosting via S3 — no public bucket access, CloudFront Origin Access Control only
- Serverless visitor counter with atomic DynamoDB updates (safe under concurrent requests)
- CORS locked to the site's actual domains, not *
- Infrastructure entirely defined in Terraform, with remote state (S3 + DynamoDB locking)
- Two independent CI/CD pipelines (GitHub Actions), scoped by path filters:
- Frontend — syncs to S3 and invalidates CloudFront on every push to frontend/
- Backend — runs the Python test suite, then plans and applies Terraform on every push to backend/ or terraform/, gated behind passing tests
- Authentication via GitHub OIDC — no long-lived AWS credentials stored anywhere
- Unit tests for the Lambda (pytest + moto), run against a mocked DynamoDB
- Production-style cloud architecture throughout
---

## Project Structure

```
cloud-resume-challenge/
│
├── .github/
│   └── workflows/
│       ├── frontend.yml        # S3 sync + CloudFront invalidation
│       └── backend.yml         # pytest -> terraform plan/apply
│
├── frontend/                   # Static site
│   ├── index.html
│   ├── style.css
│   ├── script.js                # includes visitor-counter fetch logic
│   ├── favicon.png
│   ├── robots.txt
│   └── sitemap.xml
│
├── backend/                    # Visitor-counter API
│   ├── lambda_function.py
│   ├── requirements.txt         # Lambda runtime deps
│   ├── requirements-dev.txt     # pytest, moto
│   └── tests/
│       └── test_lambda.py
│
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                  # provider, S3, CloudFront, ACM, remote backend
│   ├── lambda.tf                # Lambda + packaging
│   ├── api_gateway.tf           # API Gateway, integration, route, stage
│   ├── variables.tf
│   ├── outputs.tf
│   └── .terraform.lock.hcl
│
├── .gitignore
├── deploy.sh                   # Local frontend deployment helper
└── README.md
```

---

## Setup & Deployment

### Prerequisites

* AWS CLI configured (using `aws configure`)
* Terraform installed
* An AWS account with the right permissions

---

**1. Clone the repository**

```
bash
git clone https://github.com/ayo-d09/cloud-resume-challenge.git
cd cloud-resume-challenge
```
**3. Run the backend tests**
```
bash
pip install -r backend/requirements-dev.txt
pytest backend/tests -q
```
**4. Initialize and apply Terraform**
```
bash
cd terraform
terraform init
terraform plan
terraform apply
```
This provisions the full stack: S3, CloudFront, ACM, DynamoDB, Lambda, API Gateway, IAM roles, and CloudWatch/SNS alerting.

**5. Deploy the frontend**
```
bash
cd ..
chmod +x deploy.sh
./deploy.sh
```
Uploads the site to S3 and invalidates the CloudFront cache.


---

## Security Best Practices

* S3 bucket is **not publicly accessible**
* Access is restricted using **CloudFront Origin Access Control (OAC)**
* IAM follows the **principle of least privilege**
* HTTPS enforced via CloudFront
* Sensitive configurations are not **hardcoded**

---

## Monitoring

CloudWatch is used for:

* Traffic monitoring
* Error tracking
* Alarm configuration

---

## What I Learned

* Designing and provisioning a serverless backend (API Gateway, Lambda, DynamoDB) alongside existing static infrastructure without disrupting it
* Using DynamoDB's atomic update_item to avoid race conditions under concurrent requests, instead of a read-then-write pattern
* Writing Lambda unit tests with pytest and moto, fully mocked and independent of real AWS
* Migrating a Terraform project's state safely across a repo restructuring, and catching a state-drift issue before it caused damage
* Setting up GitHub Actions OIDC federation with AWS, including debugging a malformed IAM trust-policy condition
* Scoping a CI/CD IAM role's permissions by reading AccessDenied errors from real terraform plan runs, rather than granting broad access upfront
* Locking down CORS to specific origins, including handling multiple valid origins (bare domain + www) dynamically in Lambda

---


## Blog Post

From Static Portfolio to Full Cloud Resume Challenge: Adding a Serverless Backend on AWS (link once published)
---

## Author

**Ayomide Obadina**
Cloud & DevOps Engineer

---

## Contact

* GitHub: https://github.com/ayo-d09
* LinkedIn: https://www.linkedin.com/in/ayomide-obadina-35b09937b?
* X: https://x.com/ayobuilds?s=11
---

## License

This project is licensed under the MIT License.
