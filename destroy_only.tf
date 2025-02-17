######## PROBLEM TO FIX - DESTROY RESOURCES

/* 
The problem consistes in the DESTROY action of terraform. 
When I need to run terraform destroy the S3 bucket is not empty and cannot be deleted. 
The same goes for the cloudfront distribution, the S3 bucket cannot be deleted because it's an ORIGIN for the distribution. 

I need to find a way to deal with the destroy. 
Also, the following code does not work because of this ERROR: 

│ Destroy-time provisioners and their connection configurations may only reference attributes of the related resource, via 'self', 'count.index', or 'each.key'.
│
│ References to other resources during the destroy phase can cause dependency cycles and interact poorly with create_before_destroy.
╵

## FIX 
Maybe I can create a .sh script to empty the bucket, disable the distribution, wait 15 minutes for propagation and then delete it. 




# Empty S3 bucket upon destroy
resource "null_resource" "empty_s3_bucket" {
  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${aws_s3_bucket.website_bucket.id} --recursive"
  }

  depends_on = [aws_s3_bucket.website_bucket]
}

# Destroy CloudFront before the S3 bucket
resource "null_resource" "destroy_cloudfront_first" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      # Get CloudFront distribution ID
      DIST_ID="${aws_cloudfront_distribution.website_distribution.id}"
      
      # Get the ETag needed to update and delete the distribution
      ETag=$(aws cloudfront get-distribution-config --id $DIST_ID --query 'ETag' --output text)
      
      # Disable the CloudFront distribution
      aws cloudfront update-distribution \
        --id $DIST_ID \
        --default-root-object index.html \
        --enabled false \
        --if-match $ETag

      # Wait for CloudFront changes to propagate (15 minutes is a safe buffer)
      echo "Waiting for CloudFront propagation..."
      sleep 900

      # Get new ETag for deletion (since it changes after disabling)
      ETag=$(aws cloudfront get-distribution-config --id $DIST_ID --query 'ETag' --output text)

      # Delete the CloudFront distribution
      aws cloudfront delete-distribution --id $DIST_ID --if-match $ETag

      echo "CloudFront distribution $DIST_ID deleted."
    EOT
  }

  depends_on = [aws_cloudfront_distribution.website_distribution]
}



*/