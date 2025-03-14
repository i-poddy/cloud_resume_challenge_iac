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

# Attach policy to the user
resource "aws_iam_user_policy_attachment" "github_actions_policy" {
  user       = aws_iam_user.github_actions_user.name
  policy_arn = aws_iam_policy.lambda_deploy_policy.arn
}

# Store GitHub Secrets for GitHub Actions
resource "github_actions_secret" "aws_access_key_id_backend" {
  repository      = var.github_backend_repo
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.github_actions_key.id
}

resource "github_actions_secret" "aws_secret_access_key_backend" {
  repository      = var.github_backend_repo
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.github_actions_key.secret
}

resource "github_actions_variable" "aws_s3_artifacts_backend" {
  repository    = var.github_backend_repo
  variable_name = "AWS_S3_ARTIFACTS"
  value         = aws_s3_bucket.lambda_artifacts.id
}

resource "github_actions_variable" "aws_deploy_region_backend" {
  repository    = var.github_backend_repo
  variable_name = "AWS_DEFAULT_REGION"
  value         = "us-east-1"
}