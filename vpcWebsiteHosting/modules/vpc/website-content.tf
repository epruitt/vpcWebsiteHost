# MIME types for common web assets
locals {
  content_types = {
    ".html"        = "text/html"
    ".css"         = "text/css"
    ".js"          = "application/javascript"
    ".png"         = "image/png"
    ".jpg"         = "image/jpeg"
    ".jpeg"        = "image/jpeg"
    ".svg"         = "image/svg+xml"
    ".json"        = "application/json"
    ".webmanifest" = "application/manifest+json"
    ".ico"         = "image/x-icon"
  }

  # Get all files recursively from the website folder
  website_files = fileset("${path.module}/website", "**/*")
}

# Upload each file individually to S3
resource "aws_s3_object" "website_content" {
  for_each = local.website_files

  bucket = aws_s3_bucket.omnifood_website.id
  key    = each.value
  source = "${path.module}/website/${each.value}"
  etag   = filemd5("${path.module}/website/${each.value}")

  # Assign correct Content-Type based on file extension
  content_type = lookup(
    local.content_types,
    ".${split(".", each.value)[length(split(".", each.value)) - 1]}",
    "application/octet-stream"
  )

  tags = merge(var.tags, { Name = "website-asset-${each.value}" })
}