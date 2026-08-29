# AWS DevOps Assignment

## Overview

This project implements a containerized Streamlit application deployed to AWS with infrastructure provisioned using Terraform and an automated GitHub Actions CI/CD pipeline.

## Architecture

The deployment consists of:

- GitHub Actions for CI/CD
- GitHub Actions OIDC authentication to AWS IAM
- Amazon ECR for container image storage
- Amazon EC2 for application hosting
- Application Load Balancer for HTTP access
- VPC with public and private subnets
- NAT Gateway for private subnet egress
- Amazon RDS PostgreSQL
- AWS Secrets Manager for database credentials
- EC2 Instance Connect for deployment access
- Trivy for filesystem and container image security scanning
- Terraform for infrastructure as code

## CI/CD Pipeline

The pipeline performs:

1. Python dependency installation
2. Unit tests
3. Docker image build
4. Application startup and health check
5. Integration tests
6. Trivy filesystem security scan
7. AWS authentication using GitHub OIDC
8. Docker image security scan
9. Push to Amazon ECR
10. Staging deployment to EC2
11. Application health verification
12. EC2 container verification
13. Production approval gate
14. Failure notification through Slack when configured

## Deployment

The staging application is exposed through an Application Load Balancer.

Health endpoint:

`/_stcore/health`

The application returns:

`ok`

## Infrastructure

Terraform manages the AWS resources and maintains the deployment state.

The real `terraform.tfvars` file is intentionally excluded from Git. A `terraform.tfvars.example` file is provided as a configuration template.

## Security

The deployment uses:

- GitHub OIDC instead of long-lived AWS credentials
- IAM roles with scoped permissions
- ECR image scanning with Trivy
- Filesystem security scanning with Trivy
- AWS Secrets Manager for database credentials
- Security groups controlling network access
- Private subnets for internal resources

## Verification

The final deployment was verified successfully with:

- Terraform validation
- Successful GitHub Actions CI/CD run
- Successful Docker image scan
- Healthy EC2 container
- Successful Streamlit health check
- Healthy ALB target
- Successful ALB health check
