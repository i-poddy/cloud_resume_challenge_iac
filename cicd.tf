# Import credentials to access perform actions in github
provider "github" {
  token = var.github_token
  owner = var.github_username
}

# S3 bucket where github actions uploads lambda artifacts
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${aws_lambda_function.visit_counter.id}-artifacts-${random_string.suffix.result}" # Reused the random string used in main for the website bucket
}

# IAM user for GitHub Actions
resource "aws_iam_user" "github_actions_user" {
  name = "github-actions-user"
}

resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions_user.name
}

# IAM policy for Lambda updates and S3 uploads
resource "aws_iam_policy" "lambda_deploy_policy" {
  name        = "LambdaDeployPolicy"
  description = "Policy to update Lambda and upload to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = format("arn:aws:s3:::%s/*", aws_s3_bucket.lambda_artifacts.id)
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:UpdateFunctionCode", "lambda:PublishVersion"]
        Resource = aws_lambda_function.visit_counter.arn
      }
    ]
  })
}

# IAM policy for Frontend S3 Upload
resource "aws_iam_policy" "website_deploy_policy" {
  name        = "FrontendDeployPolicy"
  description = "Policy to update upload to S3 static website"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Resource = format("arn:aws:s3:::%s/*", aws_s3_bucket.website_bucket.id)
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = format("arn:aws:s3:::%s", aws_s3_bucket.website_bucket.id)
      }
    ]
  })
}

# Define a list of policy ARNs to attach
locals {
  policies = {
    lambda_policy = aws_iam_policy.lambda_deploy_policy.arn,
    website_policy = aws_iam_policy.website_deploy_policy.arn
  }
}

# Attach policies to the user
resource "aws_iam_user_policy_attachment" "github_actions_policy" {
  for_each   = local.policies
  user       = aws_iam_user.github_actions_user.name
  policy_arn = each.value
}

# Repositories list
locals {
  github_repos = {
    backend = var.github_backend_repo, 
    frontend = var.github_frontend_repo
  }
}

# Store GitHub Secrets for GitHub Actions
resource "github_actions_secret" "aws_access_key_id" {
  for_each       = local.github_repos
  repository     = each.value
  secret_name    = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.github_actions_key.id
}

resource "github_actions_secret" "aws_secret_access_key" {
  for_each       = local.github_repos
  repository     = each.value
  secret_name    = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.github_actions_key.secret
}

resource "github_actions_variable" "aws_deploy_region" {
  for_each     = local.github_repos
  repository   = each.value
  variable_name = "AWS_DEFAULT_REGION"
  value         = "us-east-1"
}

# Store GitHyb repo-specific variables to be used for GitHub Actions - Backend Repo
resource "github_actions_variable" "aws_s3_artifacts_backend" {
  repository    = var.github_backend_repo
  variable_name = "AWS_S3_ARTIFACTS"
  value         = aws_s3_bucket.lambda_artifacts.id
}

# Store GitHyb repo-specific variables to be used for GitHub Actions - Frontend Repo
resource "github_actions_variable" "aws_s3_website_frontend" {
  repository    = var.github_frontend_repo
  variable_name = "AWS_S3_WEBSITE"
  value         = aws_s3_bucket.website_bucket.id
}

resource "github_actions_variable" "aws_s3_api_backend" {
  repository    = var.github_frontend_repo
  variable_name = "AWS_API_GW"
  value         = aws_apigatewayv2_stage.prod.invoke_url
}