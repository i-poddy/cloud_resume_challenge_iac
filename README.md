# CLOUD RESUME CHALLENGE - AWS

## Introduction

The [Cloud Resume Challenge](https://cloudresumechallenge.dev/) is a hands-on project designed to showcase cloud skills by building and deploying a resume using cloud services like AWS, Azure, or GCP. It involves frontend hosting, backend integration, infrastructure as code, CI/CD, and security best practices, demonstrating proficiency in modern cloud technologies.

[**Check out my Challenge!**](https://www.gianlucapoddighe.com/)

## Architecture

The project consists of the following components:

- **Frontend**: A static website built with HTML, CSS, and JavaScript, hosted on Amazon S3 and served via Amazon CloudFront.
- **Backend**: A serverless API implemented using AWS API Gateway, AWS Lambda (Python), and AWS DynamoDB to track visitor count.
- **CI/CD**: GitHub Actions to deploy the Frontend and Backend code to the S3 for the static website and the lambda function respectively.
- **Infrastructure as Code**: Provisioned using Terraform for repeatability and automation.

[Read more about the infrastructure](./docs/architecture.md)

## Project Status

### MVP - Version 1.0
| Component   | Status          | Notes |
|------------|----------------|-------|
| **Frontend** | Completed ✅ | S3, CloudFront configured, ok script for download frontend code, missing domain configuration on route53, integration with ACM |
| **Backend**  | Completed ✅ | API Gateway, Lambda, DynamoDB, IAM roles, and monitoring implemented, also implemented JS on frontend |
| **CI/CD**    | Completed ✅ | Github actions deploy the code from frontend and backend repository to the respective targets, all configurations, users and permissions on AWS and secrets and vars in Github, are configured with terraform |

### Add-on and improvements
| Component   | Status          | Notes |
|------------|----------------|-------|
| **Logging**           | Planned 🔜      | Implement a better logging for the environment and, especially, for the lambda execution, also implement dashboard and alarms in Cloudwatch for observability |
| **Cleanup Script**    | Planned 🔜      | Create a bash and/or powershell script to perform actions needed before destroy |
| **Improved CI/CD**    | Planned 🔜      | Write testing units and incorporate them in the CI/CD |
| **Better frontend**   | Planned 🔜      | Recreate the frontend with better UI/UX design and improve the codebase |
| **Subdomain usage**   | Planned 🔜      | Refactoring the terraform code to use a subdomain resume.gioanlucapoddighe.com instead of the root domain |
| **API GW Subdomain**  | Planned 🔜      | Refactoring the code for API Gateway to make it available at resume-api.gianlucapoddighe.com |
| **Refactoring**       | Planned 🔜      | Refactoring the terraform code to a better structure to support different environments (dev, staging, prod) |

## Deployment Steps

### Prerequisites

- AWS account with access keys
- AWS CLI configured
- Terraform installed
- Domain registered on Route53
- 3 GitHub repositories: one for IaC, one for Frontend, one for Backend with access token

### Deploy

Specify your .tfvars file when you deploy your infrastructure
- Verify your configuration: `terraform validate`
- Set your environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION
- Configure your local variables using terraform.tfvars files (I have prepared a .tfvars.template you can use)
- Plan your deployment: `terraform plan --file-var=terraform.tfvars`
- Execute and create: `terraform apply --file-var=terraform.tfvars`
- Commit your frontend and backend repository to deploy them

DO NOT COMMIT YOUR .tfvars FILES OR YOUR ENVIRONMENT VARIABLES! 

### Notes

To destroy the infrastructure you should first manually disable and delete the CloudFront deployment.
Then run `terraform destroy`

## Author

[**Gianluca Poddighe**](https://www.linkedin.com/in/gianluca-poddighe/) - Cloud Engineer & Solution Architect | AWS Certified

## License

This project is licensed under the MIT License.
