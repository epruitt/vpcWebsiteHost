#Random String
resource "random_string" "suffix" {
  length           = 6
  special          = false
  upper         = false
}

# create s3  website asset bucket
resource "aws_s3_bucket" "omnifood_website"{
   bucket = "omnifood-website-${var.environment_name}-${var.aws_region}-${random_string.suffix.result}"

   tags={
    Name = "Omnifood website-${var.environment_name}-${var.aws_region}"
    Enviroment = var.environment_name
    Purpose = "website assets"
   } 
}

# block public access
resource "aws_s3_bucket_public_access_block" "omnifood_website"{
    bucket = aws_s3_bucket.omnifood_website.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

#Enable versioning
resource "aws_s3_bucket_versioning" "omnifood_website"{
    bucket = aws_s3_bucket.omnifood_website.id

    versioning_configuration {
        status = "Enabled"
    }
}

#Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "omnifood_website"{
    bucket = aws_s3_bucket.omnifood_website.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

#s3 bucket public access block
resource "aws_s3_bucket_public_access_block" "omnifood_website_block_public" {
  bucket = aws_s3_bucket.omnifood_website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true  
}
