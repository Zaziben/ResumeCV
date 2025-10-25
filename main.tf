terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.64.0"
    }
  }
}

resource "aws_s3_bucket" "s3" {
  bucket = "joshvvcv.com"
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "pb" {
  bucket = aws_s3_bucket.s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.s3.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    "Service": "cloudfront.amazonaws.com"
                }
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.s3.arn}/*"
                Condition = {
                    StringEquals = {
                        "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
                    }
                }
            }
        ]
    })
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.ownership]
  bucket     = aws_s3_bucket.s3.id
  acl        = "private"
}

resource "aws_s3_bucket_object" "object" {
  bucket       = aws_s3_bucket.s3.bucket
  key          = "index.html"
  source       = "./index.html"
  etag         = filemd5("./index.html")
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "object1" {
  bucket       = aws_s3_bucket.s3.bucket
  key          = "visitor.js"
  source       = "./visitor.js"
  acl          = "public-read"
  content_type = "application/javascript"
}

module "visitor_table" {
  source             = "./table"
  table_name         = "joshvvcv-vstore"
  partition_key_name = "joshvvcv.com"
  tags = {
    Environment = "prod"
    App         = "website"
  }
}
module "lambda_visitor_counter" {
  source              = "./function"
  function_name       = "visitor-count"
  dynamodb_table_name = module.visitor_table.table_name
  dynamodb_table_arn  = module.visitor_table.table_arn
}
