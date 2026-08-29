# AWS DevOps Assignment

## Overview

This repository contains the end-to-end implementation of the AWS DevOps assignment.

The solution demonstrates infrastructure provisioning, containerization, CI/CD automation, security scanning, AWS secret management, monitoring, centralized logging, dashboards, and deployment verification using AWS, Terraform, Docker, and GitHub Actions.

The application itself is a containerized Streamlit application. The application logic is intentionally simple because the assignment focuses primarily on DevOps and cloud engineering practices.

---

# Architecture

```text
                           Internet
                              |
                              v
                   +----------------------+
                   | Application Load     |
                   | Balancer :80         |
                   +----------+-----------+
                              |
                    Public Subnets
                    (2 Availability Zones)
                              |
                              v
                   +----------------------+
                   | Private EC2          |
                   | Docker + Streamlit   |
                   | Port 8501            |
                   +----------+-----------+
                              |
                              v
                   +----------------------+
                   | Private RDS           |
                   | PostgreSQL            |
                   +----------------------+

GitHub
   |
   v
GitHub Actions
   |
   +---- Tests
   +---- Trivy filesystem scan
   +---- Docker build
   +---- Trivy image scan
   +---- AWS OIDC authentication
   |
   v
Amazon ECR
   |
   v
Staging EC2
   |
   v
Application Load Balancer
