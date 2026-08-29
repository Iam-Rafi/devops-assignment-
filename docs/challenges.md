# Challenges and Resolutions


## Trivy Image Reference

The initial Trivy container scan used an image reference that was interpreted incorrectly by the action.

The scan was corrected to reference the locally built image using the repository name and Git commit SHA.

## Python Dependency Security

Trivy identified security findings in dependencies and base-image packages.

The application dependencies were updated to compatible security versions, and the Docker build was adjusted to install fixed OpenSSL package versions.

Dependency compatibility was verified during Docker image builds.

## EC2 Application Deployment

The application initially was not running on the EC2 instance, causing the load balancer health check to fail.

The ECR image was pulled manually to verify the deployment image, the application container was started on port 8501, and the Streamlit health endpoint was confirmed to return `200 OK`.

The ALB target subsequently became healthy.
