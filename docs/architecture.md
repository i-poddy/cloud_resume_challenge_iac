# CLOUD RESUME CHALLENGE - INFRASTRUCTURE

## Architecture components overview

The project consists of the following components:

- **Frontend**: A static website built with HTML, CSS, and JavaScript, hosted on Amazon S3 and served via Amazon CloudFront.
- **Backend**: A serverless API implemented using AWS API Gateway, AWS Lambda (Python), and AWS DynamoDB to track visitor count.
- **CI/CD**: GitHub Actions to deploy the Frontend and Backend code to the S3 for the static website and the lambda function respectively.
- **Infrastructure as Code**: Provisioned using Terraform for repeatability and automation.

## Architecture Diagram

![Architecture-diagram](../images/cloud-resume-challenge-infrastructure-diagram.png)

The Diagram represent the architecture implemented for my Cloud Resume Challenge. 
I have used three different colors to represent the four main components of the infrastrucuture and the workflows.

### Infrastructure as Code: Green

- <span style="color: green;">1</span> From GitHub IaC repository the Owner download the Source Code
- <span style="color: green;">2</span> The Owner of the Project runs the Terraform code with the appropriate variables
- <span style="color: green;">3</span> Terraform creates the AWS Cloud Resources
- <span style="color: green;">4</span> Terraform creates the secrets and variables in GitHub Frontend and Backend repositories to be used by the GitHub Actions

### Frontend and backend source code and CI/CD: Blue

- <span style="color: blue;">1</span> The Developer commits the code to the Frontend and Backend repositories  
- <span style="color: blue;">2</span> The Commit event in the Frontend or in the Frontend repositories trigger the GitHub Action execution
- <span style="color: blue;">3</span> The Frontend GitHub Action uses the variables set by terraform, modify the Javascipt file with the API Gateway Endpoint, and deploys the code to the S3 static website bucket
- <span style="color: blue;">4</span> The Backend GitHub Action zip the python code and upload it to a S3 bucket created for artifacts
- <span style="color: blue;">5</span> The Backend GitHub Action get the .zip artifact and deploys it to the Lambda Function

### Frontend and Backend resources: Orange

- <span style="color: orange;">1</span> The user (or visitor) access [cloud Resume Challenge](https://cloudresumechallenge.dev/) and his browser queries the DNS server
- <span style="color: orange;">2</span> The DNS implemented with the Route53 service forward him to the Cloudfront Distribution Endpoint
- <span style="color: orange;">3</span> The Cloudfront Distribution uses ACM to get the certificate to serve the content in HTTPS  
- <span style="color: red;">4 (Conditional) </span> **if** the user request is a **cache miss** on the Cloudfront Distribution cache, the CloudFront Distribution get the content from S3  
- <span style="color: red;">5 (Conditional) </span> S3 return the Website content to the Cloudfront Distribution
- <span style="color: orange;">6</span> The DNS implemented with the Route53 service forward him to the Cloudfront Distribution Endpoint
- <span style="color: orange;">7</span> The user browser displays the website to the user and executes the Javasciript which perform a request to the API Gateway to retrieve the Visitor Counter which is now showing **Loading**
- <span style="color: orange;">8</span> The API Gateway forward the request to the Lambda function and triggers its execution
- <span style="color: orange;">9</span> The Lambda function retrieve the visitor count from the DynamoDB table 
- <span style="color: orange;">10</span> The DynamoDB return the visitor counter to the Lambda function
- <span style="color: orange;">11</span> The Lambda function return the visitor counter to the API Gateway
- <span style="color: orange;">11</span> The API Gateway return the visitor counter to the user browser which will display it to the user along with the website