# Implementation Approach

## Infrastructure

Terraform was used to provision and manage the AWS infrastructure. The configuration separates networking, compute, load balancing, database, IAM, security, secrets, monitoring, and container registry resources into separate files.

The environment uses a VPC with public and private subnets across multiple availability zones. The application runs on EC2 while the database is hosted by Amazon RDS.

## CI/CD

GitHub Actions is responsible for validating, testing, scanning, building, publishing, and deploying the application.

The pipeline first runs unit and integration tests. A Docker image is then built and scanned with Trivy before being pushed to Amazon ECR.

AWS authentication uses GitHub Actions OIDC and an IAM role rather than storing long-lived AWS access keys in GitHub.

## Deployment

The staging deployment uses EC2 Instance Connect to establish temporary SSH access. The deployment process:

1. Authenticates to Amazon ECR.
2. Pulls the image associated with the Git commit SHA.
3. Removes the previous application container.
4. Starts the new container.
5. Verifies the Streamlit health endpoint.
6. Verifies that the container is running.

The Application Load Balancer performs its own health check against the Streamlit health endpoint.

## Security

Security scanning is performed both against the source filesystem and the final container image.

The container base image packages are updated during the image build, and vulnerable OpenSSL packages identified during scanning were pinned to fixed package versions.

## Verification

The final deployment was verified at the application, container, target group, load balancer, ECR, Terraform, and CI/CD levels.
