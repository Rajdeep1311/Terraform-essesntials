variable "aws_region" {
  description = "The AWS region where resources will be created."
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for the static website."
  default     = "terraform-cloudfront"
}

variable "index_html_path" {
  description = "The local path to the index.html file."
  default     = "index.html"
}

variable "acl_permission" {
  description = "The ACL permission for the S3 bucket."
  default     = "public-read"
}
