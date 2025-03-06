# CLOUD RESUME CHALLENGE - AWS

## Introduction

The Cloud Resume Challenge is a hands-on project designed to showcase cloud skills by building and deploying a resume using cloud services like AWS, Azure, or GCP. It involves frontend hosting, backend integration, infrastructure as code, CI/CD, and security best practices, demonstrating proficiency in modern cloud technologies.

## Architecture

The project consists of the following components:

- **Frontend**: A static website built with HTML, CSS, and JavaScript, hosted on Amazon S3 and served via Amazon CloudFront.
- **Backend**: A serverless API implemented using AWS API Gateway, AWS Lambda (Python), and AWS DynamoDB to track visitor count.
- **Infrastructure as Code**: Provisioned using Terraform for repeatability and automation.
- **CI/CD**: GitHub Actions or AWS CodePipeline automating deployments for both frontend and backend.
- **Monitoring**: CloudWatch for logs and error tracking.

## Deployment Steps

### Prerequisites

- AWS account
- AWS CLI configured
- Terraform installed
- Already purchased Domain
- 3 GitHub repositories: one for IaC, one for Frontend, one for Backend

### Notes

To destroy the infrastructure you should first manually disable and delete the CloudFront deployment.

## Author

Gianluca Poddighe - Cloud Engineer & Solution Architect | AWS Certified

## License

This project is licensed under the MIT License.
