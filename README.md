# AWS DevOps Assignment

## Overview

This repository contains an end-to-end AWS DevOps implementation covering infrastructure provisioning, containerization, CI/CD automation, security scanning, monitoring, centralized logging, secret management, database backup, and deployment verification.

The application is a simple containerized Streamlit application. The application logic is intentionally lightweight because the primary focus of this assignment is the DevOps implementation.

---

## Architecture

```text
                           Internet
                              |
                              v
                  +-----------------------+
                  | Application Load      |
                  | Balancer :80          |
                  +-----------+-----------+
                              |
                    Public Subnets
                    AZ-a / AZ-b
                              |
                              v
                  +-----------------------+
                  | Private EC2           |
                  | Docker + Streamlit    |
                  | Port 8501             |
                  +-----------+-----------+
                              |
                              v
                  +-----------------------+
                  | Private RDS            |
                  | PostgreSQL             |
                  +------------------------+

GitHub
   |
   v
GitHub Actions
   |
   +-- Tests
   +-- Trivy filesystem scan
   +-- Docker build
   +-- Trivy image scan
   +-- AWS OIDC
   |
   v
Amazon ECR
   |
   v
Staging EC2
```

### AWS Resources

* VPC
* Public and private subnets across two Availability Zones
* Internet Gateway
* NAT Gateway
* Application Load Balancer
* EC2 application instance
* Docker / Streamlit
* Amazon ECR
* Amazon RDS PostgreSQL
* AWS Secrets Manager
* Amazon CloudWatch
* EC2 Instance Connect Endpoint
* IAM roles and policies
* GitHub Actions OIDC

---

# Part 1 — Infrastructure Provisioning

Terraform is used to provision and manage the AWS infrastructure.

## Network

The VPC uses:

| Resource           | Configuration                        |
| ------------------ | ------------------------------------ |
| VPC                | `10.0.0.0/16`                        |
| Public subnet 1    | `10.0.1.0/24`                        |
| Public subnet 2    | `10.0.2.0/24`                        |
| Private subnet 1   | `10.0.11.0/24`                       |
| Private subnet 2   | `10.0.12.0/24`                       |
| Availability Zones | `ap-southeast-1a`, `ap-southeast-1b` |

The ALB is internet-facing and deployed in the public subnets.

The application EC2 instance runs in a private subnet.

RDS PostgreSQL is deployed in private subnets and is accessible only from the application security group.

A NAT Gateway provides outbound connectivity for private resources.

## Security Groups

Traffic is restricted using security groups:

* ALB: HTTP `80` from the internet
* EC2: application port `8501` only from the ALB security group
* EC2: SSH only from the EC2 Instance Connect Endpoint security group
* RDS: PostgreSQL `5432` only from the EC2 security group

## Terraform Variables

Configurable parameters are provided through `terraform/variables.tf`, including:

* AWS region
* Environment
* VPC CIDR
* Availability Zones
* Public subnet CIDRs
* Private subnet CIDRs
* EC2 instance type
* RDS instance class
* Database name
* Database username
* SSH public key

## Terraform State

Terraform state is stored remotely in Amazon S3.

```text
Bucket: terraform-s3-state-log
Key:    devops-assignment/terraform.tfstate
Region: ap-southeast-1
Encryption: enabled
Locking: enabled
```

The real `terraform.tfvars` file is excluded from Git.

## Terraform Outputs

Key resources are exposed through Terraform outputs:

* VPC ID
* Public subnet IDs
* Private subnet IDs
* EC2 instance ID
* EC2 private IP
* RDS endpoint
* RDS port
* ALB DNS name
* ECR repository URL
* Secrets Manager ARN
* EC2 Instance Connect Endpoint ID
* GitHub Actions IAM role ARN

---

# Part 2 — Deployment Automation

GitHub Actions is used for CI/CD.

Workflows:

```text
.github/workflows/
├── ci-cd.yml
└── auto-pr.yml
```

## Pull Request / Code Review

Code changes are developed on branches rather than directly deploying application changes from arbitrary branches.

The `auto-pr.yml` workflow creates a pull request automatically when application, Docker, or workflow code is pushed to a non-main branch.

Monitored paths:

```text
app/**
docker/**
.github/workflows/**
```

This provides a code-review step before merging changes into `main`.

## CI/CD Trigger

The CI/CD workflow is restricted to relevant code changes:

```text
app/**
docker/**
.github/workflows/**
```

Therefore documentation-only changes do not trigger the application CI/CD pipeline.

## Pipeline

The CI/CD pipeline performs:

1. Install Python dependencies
2. Run unit tests
3. Build Docker image
4. Start the application
5. Run application health check
6. Run integration tests
7. Run Trivy filesystem vulnerability scan
8. Authenticate to AWS using GitHub OIDC
9. Run Trivy container image scan
10. Push the Docker image to Amazon ECR
11. Discover the current staging EC2 instance dynamically
12. Deploy the image to staging
13. Verify the staging container
14. Verify the application health endpoint
15. Production approval gate
16. Production deployment
17. Slack failure notification when configured

## AWS Authentication

GitHub Actions uses OIDC to assume a dedicated AWS IAM role.

No long-lived AWS access keys are stored in the GitHub repository.

## Container Registry

Amazon ECR stores the application images.

ECR is configured with:

* Image scanning on push
* Mutable tags
* Lifecycle policy retaining the latest 10 images

Images are also scanned with Trivy before deployment.

## Dynamic EC2 Discovery

The deployment workflow discovers the running staging EC2 instance using its AWS tags rather than relying on a hard-coded instance ID or IP address.

This allows Terraform to recreate the EC2 instance without requiring manual changes to the CI/CD workflow.

## Production Approval

Production deployment is separated into a GitHub Actions production environment and can require manual approval before the deployment proceeds.

---

# Part 3 — Monitoring and Logging

Amazon CloudWatch is used for monitoring and centralized logging.

## Infrastructure Metrics

The EC2 environment collects:

* CPU utilization
* Memory utilization
* Disk utilization

The CloudWatch Agent runs on the EC2 instance and publishes memory and disk metrics to:

```text
DevOpsAssignment/EC2
```

## Application Metrics

Application traffic is monitored through the Application Load Balancer.

Relevant metrics include:

* Request count
* HTTP 5xx errors
* Target 5xx errors
* Target response time
* Target health

## Application Health

The Streamlit application exposes:

```text
/_stcore/health
```

Expected response:

```text
ok
```

The ALB target group uses this endpoint as its health check.

## Database Metrics

RDS monitoring includes:

* CPU utilization
* Database connections
* Free storage

## Centralized Logging

CloudWatch Logs centralize:

```text
/aws/ec2/staging-devops-assignment/application
/aws/ec2/staging-devops-assignment/system
/aws/ec2/staging-devops-assignment/docker
```

These provide visibility into:

* Application logs
* System/cloud-init logs
* Docker/container logs

## CloudWatch Dashboards

Two dashboards are provisioned.

### Application Dashboard

Provides visibility into:

* ALB requests
* ALB errors
* Target errors
* Response time
* EC2 CPU
* RDS indicators

### Infrastructure Dashboard

Provides visibility into:

* EC2 CPU
* EC2 memory
* EC2 disk usage
* RDS CPU
* RDS database connections
* RDS free storage

---

# Part 4 — Documentation and Best Practices

## Secret Management

Database credentials are generated and stored in AWS Secrets Manager.

The secret contains:

```text
username
password
database
```

Sensitive local configuration is excluded from Git:

```text
terraform.tfvars
*.pem
*.key
.env
```

## Backup Strategy

Amazon RDS automated backups are enabled.

The staging database uses a 7-day backup retention period.

For a production environment, backup retention and restore testing should be adjusted according to business requirements.

## Cost Optimization

The assignment environment uses cost-conscious resource sizing:

* `t3.micro` EC2
* `db.t3.micro` RDS
* GP3 storage
* Limited CloudWatch log retention
* ECR lifecycle policy retaining the latest 10 images
* Small staging environment

Production sizing would be adjusted based on workload requirements.

---

# Security

Security controls implemented include:

* GitHub OIDC instead of long-lived AWS credentials
* IAM roles with scoped permissions
* Private EC2 subnet
* Private RDS subnets
* Security-group-based traffic restrictions
* ALB-only access to application port `8501`
* EC2 Instance Connect for administrative SSH access
* Secrets Manager for database credentials
* Trivy filesystem scanning
* Trivy container image scanning
* ECR scan-on-push
* No secrets committed to Git

---

# Application

The application is a containerized Streamlit application.

## Docker

The Docker image:

* Uses Python 3.12
* Runs Streamlit on port `8501`
* Runs as a containerized application
* Includes a Docker health check

Health check:

```text
http://localhost:8501/_stcore/health
```

## Run Locally

Install dependencies:

```bash
pip install -r app/requirements.txt
```

Run:

```bash
streamlit run app/app.py
```

Or build the Docker image:

```bash
docker build -f docker/Dockerfile -t devops-assignment:local .
```

Run:

```bash
docker run --rm -p 8501:8501 devops-assignment:local
```

Verify:

```bash
curl http://localhost:8501/_stcore/health
```

Expected:

```text
ok
```

---

# Testing

## Unit Tests

Tests are located at:

```text
app/tests/test_logic.py
```

Run:

```bash
pytest app/tests/test_logic.py -v
```

## Integration Test

The integration test validates the running Streamlit application:

```text
app/tests/test_integration.py
```

Run:

```bash
pytest app/tests/test_integration.py -v
```

---

# Terraform Usage

## Prerequisites

* AWS CLI
* Terraform
* Docker
* Python 3.12
* Git

## Configure Terraform

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Populate the required variables.

Do not commit `terraform.tfvars`.

## Initialize

```bash
terraform -chdir=terraform init
```

## Format

```bash
terraform -chdir=terraform fmt
```

## Validate

```bash
terraform -chdir=terraform validate
```

## Plan

```bash
terraform -chdir=terraform plan
```

## Apply

```bash
terraform -chdir=terraform apply
```

---

# Project Structure

```text
.
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── tests/
│       ├── test_logic.py
│       └── test_integration.py
│
├── docker/
│   ├── Dockerfile
│   └── .dockerignore
│
├── terraform/
│   ├── backend.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── networking.tf
│   ├── security.tf
│   ├── ec2.tf
│   ├── alb.tf
│   ├── rds.tf
│   ├── ecr.tf
│   ├── secrets.tf
│   ├── iam.tf
│   ├── monitoring.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── .github/
│   └── workflows/
│       ├── ci-cd.yml
│       └── auto-pr.yml
│
├── docs/
│   ├── approach.md
│   └── challenges.md
│
├── .gitignore
└── README.md
```

---

# Verification

The implementation has been verified through:

* Terraform formatting
* Terraform validation
* Terraform plan
* Unit tests
* Integration tests
* Docker image build
* Trivy filesystem scan
* Trivy container image scan
* ECR image push
* EC2 container deployment
* Streamlit health check
* ALB target health check
* ALB health endpoint
* CloudWatch EC2 metrics
* CloudWatch logs
* GitHub Actions CI/CD run
* Automatic pull-request creation test

---

# Challenges and Resolutions

Detailed challenges and their resolutions are documented in:

```text
docs/challenges.md
```

The document covers issues encountered during implementation, troubleshooting steps, and the final resolutions.

---

# Assignment Deliverables

## GitHub Repository

**Repository:**

[https://github.com/Iam-Rafi/devops-assignment-](https://github.com/Iam-Rafi/devops-assignment-)

## Approach Documentation

* `README.md`
* `docs/approach.md`

## Challenges Document

* `docs/challenges.md`

The challenges document should be submitted as a PDF or Word document as requested by the assignment.

## Loom Video

The Loom recording should demonstrate:

1. Repository structure
2. Terraform infrastructure
3. AWS architecture
4. CI/CD workflow
5. Docker and ECR
6. Staging deployment
7. Running application
8. ALB health check
9. CloudWatch dashboards
10. CloudWatch logs
11. Security scanning
12. Secret management
13. Challenges and resolutions

---

# Conclusion

This project provides an end-to-end AWS DevOps implementation covering:

**Infrastructure as Code → Secure AWS Infrastructure → Docker → CI/CD → Security Scanning → ECR → Staging Deployment → Production Approval → Monitoring → Centralized Logging → Secrets Management → Backups → Documentation**

The implementation is designed to satisfy the requirements of the AWS DevOps assignment while keeping the application itself intentionally simple and focusing on DevOps engineering practices.

