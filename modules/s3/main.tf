#############
# S3 bucket #
#############
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.additional_tags
}

##############
# Bucket ACL #
##############
resource "aws_s3_bucket_acl" "default" {
  depends_on = [aws_s3_bucket_ownership_controls.default]

  bucket = aws_s3_bucket.default.id
  acl    = var.bucket_acl
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id
  rule {
    object_ownership = var.object_ownership
  }
}

#####################
# Bucket versioning #
#####################
resource "aws_s3_bucket_versioning" "default" {
  for_each = var.enable_versioning ? toset(["enabled"]) : []

  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = "Enabled"
  }
}

#####################
# SSE configuration #
#####################
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  for_each = length(keys(var.server_side_encryption_configuration)) > 0 ? toset(["enabled"]) : []

  bucket = aws_s3_bucket.default.id

  dynamic "rule" {
    for_each = try(flatten([var.server_side_encryption_configuration["rule"]]), [])

    content {
      bucket_key_enabled = try(rule.value.bucket_key_enabled, null)

      dynamic "apply_server_side_encryption_by_default" {
        for_each = try([rule.value.apply_server_side_encryption_by_default], [])

        content {
          sse_algorithm     = apply_server_side_encryption_by_default.value.sse_algorithm
          kms_master_key_id = try(apply_server_side_encryption_by_default.value.kms_master_key_id, null)
        }
      }
    }
  }
}

###################
# Bucket policies #
###################
resource "aws_s3_bucket_policy" "default" {
  for_each = var.attach_policy ? toset(["enabled"]) : []

  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.combined["enabled"].json
}

data "aws_iam_policy_document" "combined" {
  for_each = var.attach_policy ? toset(["enabled"]) : []

  source_policy_documents = compact([
    var.require_ssl_requests ? data.aws_iam_policy_document.require_ssl_requests.json : "",
    var.policy
  ])
}

# Policy to require requests to use HTTPS/SSL. This explicitly denies access HTTP requests to the bucket.
data "aws_iam_policy_document" "require_ssl_requests" {
  version = "2012-10-17"

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.default.arn}/*",
      "${aws_s3_bucket.default.arn}"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

##############################
# Bucket public access block #
##############################
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}
