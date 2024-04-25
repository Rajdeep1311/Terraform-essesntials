terraform {
  backend "s3" {
    bucket     = "rajdeep-terraform-backend"
    key        = "terraform.tfstate"
    region     = "us-east-1"
    access_key = "s"
    secret_key = "s"
  }
}

provider "aws" {
  region = var.aws_region # Change this to your desired AWS region
}

resource "aws_s3_bucket" "static_website" {
  bucket = var.s3_bucket_name # Change this to your desired bucket name
  object_lock_enabled = false

  tags = {
    Name      = "StaticWebsiteBucket"
    CreatedBy = "Rajdeep"
  }
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketPolicy"
  description = "IAM policy to allow managing S3 buckets and ACLs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:*"
        ],
        Resource = "arn:aws:s3:::terraform-cloudfront/*"
      }
    ]
  })
}

resource "aws_s3_bucket_acl" "static_website_acl" {
  bucket = aws_s3_bucket.static_website.id

  acl = var.acl_permission
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.static_website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.static_website_access_block]
}

resource "aws_s3_bucket_public_access_block" "static_website_access_block" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets  = false
}

resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_distribution" "cdn_distribution" {
  origin {
    domain_name = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "CDNDistribution"
    CreatedBy = "Rajdeep"
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_website.id
  key    = "index.html"
  source = var.index_html_path  # Update this with the actual path to your index.html file
  acl    = var.acl_permission
  content_type = "text/html"
  depends_on = [aws_s3_bucket.static_website, aws_cloudfront_distribution.cdn_distribution]
}
