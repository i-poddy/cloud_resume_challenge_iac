/* 
Name: Cloud Resume Challenge - AWS - Gianluca Poddighe
Description: Cloud Resume Challenge, AWS based, for Gianluca Poddighe
Contributors: Gianluca Poddighe
*/

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Owner       = "Gianluca"
      ManagedBy   = "Terraform"
      Environment = terraform.workspace
      Project     = var.project_name
    }
  }
}

/* 
FRONTEND
Host the frontend on S3, use Cloudfront to distribute the content.
*/

# Create Random String for S3 bucket name
resource "random_string" "suffix" {
  length  = 12
  special = false
  upper   = false
}

# Create Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "cloud-resume-challenge-${random_string.suffix.result}" # Use that random string for unique name
}

# Enable website hosting on the bucket
# Need to fix the error_document 
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Make the bucket private
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create an S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cloudfront_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_s3_policy.json
}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website_distribution.arn]
    }
  }
}

# Create a CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-${aws_s3_bucket.website_bucket.id}"
  description                       = "OAC for S3 private website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  # Add Alternate Domain Names (CNAMEs) here
  aliases = ["${var.my_domain}", "www.${var.my_domain}"]

  # Cache behavior
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Price Class (selecting Price Class 100 for cheaper cost) Use only North America and Europe
  price_class = "PriceClass_100"

  # Restrict access to CloudFront only (prevent direct S3 access)
  # Need to be edited for ACM
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Clone the GitHub repository and upload to S3
# Works on bash, but if we run from powershell we may have problems. 
# Refactor this in python? 
# Also, need to be edited for backend later
# NEED A FIX - I need to pass my ENV for the session to work
resource "null_resource" "clone_and_upload_frontend" {
  provisioner "local-exec" {
    command     = <<EOT
      git clone ${local.frontend_git_repository_url} frontend_repo
      aws s3 sync frontend_repo s3://${aws_s3_bucket.website_bucket.id}/ --acl private
      rm -rf frontend_repo
    EOT
    working_dir = path.module
  }


  # Ensure this runs after the S3 bucket is created
  depends_on = [aws_s3_bucket.website_bucket]
}

# Fetch the existing hosted zone for mydomain since the hosted zone already exist from domain registration
data "aws_route53_zone" "mydomain" {
  name         = var.my_domain
  private_zone = false
}

# Create a Route 53 record for www.mydomain.com pointing to CloudFront
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = "www.${var.my_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create a Route 53 record for mydomain.com (root domain) pointing to CloudFront
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = var.my_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


# ACM to deploy SSL/TLS Certificate for HTTPS
resource "aws_acm_certificate" "cert" {
  domain_name       = var.my_domain
  validation_method = "DNS"

  subject_alternative_names = ["www.${var.my_domain}"]

  lifecycle {
    create_before_destroy = true
  }
}

# Now I need to validate the certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


/* 
BACKEND
The frontend will call the API Gateway, which forwards a request to a python lambda that retrieve values from DynamoDB and send the response to the Frontend.
Need to update JS code in the frontend to use API Gateway Endpoints.
*/


# Implmenting DynamoDB table to store the counter
resource "aws_dynamodb_table" "visit_counter" {
  name         = "resume-visit-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Create IAM Role and Policy for the lambda function permissions
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda-dynamodb-access"
  description = "Allow Lambda to read from DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",    # Need to read the counter
          "dynamodb:UpdateItem", # Need to update the counter +1
          "dynamodb:PutItem"     # Need to initialize the counter if it does not exist 
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visit_counter.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# The lambda function
resource "aws_lambda_function" "visit_counter" {
  function_name = "visitor-counter"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.9"
  handler       = "lambda_visitor_counter.lambda_handler"
  filename      = "lambda_visitor_counter.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visit_counter.name
    }
  }

  depends_on                     = [aws_iam_role_policy_attachment.lambda_dynamodb_attach]
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke-1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visit_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resume_api.execution_arn}/*"
}

# Let's create the API Gateway
# HTTP API preferred to REST API because cheaper and faster
resource "aws_apigatewayv2_api" "resume_api" {
  name          = "resume-api"
  protocol_type = "HTTP"
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.resume_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visit_counter.invoke_arn
  payload_format_version = "2.0"
}

# API Gateway route
resource "aws_apigatewayv2_route" "visit_count" {
  api_id    = aws_apigatewayv2_api.resume_api.id
  route_key = "GET /visit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Deploy API
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.resume_api.id
  name        = "prod"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20 # Allow short bursts of up to 20 requests
    throttling_rate_limit  = 10 # Steady rate of 10 requests per second
  }
}

# Lambda permission to be invoked by API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visit_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resume_api.execution_arn}/*"
}

# Clone the backend repository
resource "null_resource" "upload_lambda" {
  provisioner "local-exec" {
    command = <<EOT
      cd ../cloud_resume_challenge_be
      Compress-Archive -Path * -DestinationPath lambda_visitor_counter.zip
      aws lambda update-function-code --function-name visitor-counter --zip-file fileb://lambda_visitor_counter.zip
    EOT
  }
}





# Still need to design a way to modify the frontend to use API Gateway url
# Still need to design a way to upload the lambda zip file
# CI/CD