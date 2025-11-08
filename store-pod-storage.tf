module "cdn-storage-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${var.project}-${var.pod.id}-${var.env}-cdn-"


  force_destroy = true
  tags          = var.tags
}

module "cert-storage-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${var.project}-${var.pod.id}-${var.env}-cert-"


  force_destroy = true
  tags          = var.tags
}


module "cdn-storage-cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"


  comment             = "cdn storage cloudfront distribution"
  enabled             = true
  staging             = false # If you want to create a staging distribution, set this to true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  # If you want to create a primary distribution with a continuous deployment policy, set this to the ID of the policy.
  # This argument should only be set on a production distribution.
  # ref. `aws_cloudfront_continuous_deployment_policy` resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_continuous_deployment_policy
  continuous_deployment_policy_id = null

  # When you enable additional metrics for a distribution, CloudFront sends up to 8 metrics to CloudWatch in the US East (N. Virginia) Region.
  # This rate is charged only once per month, per metric (up to 8 metrics per distribution).
  create_monitoring_subscription = true

  create_origin_access_identity = true
  origin_access_identities = {
    cdn_storage_access_identity = "My awesome CloudFront can access"
  }

  # create_origin_access_control = false
  # origin_access_control = {
  #   cdn_storage = {
  #     description      = "CloudFront access to S3"
  #     origin_type      = "s3"
  #     signing_behavior = "always"
  #     signing_protocol = "sigv4"
  #   }
  # }

  origin = {
    cdn_storage = {
      # with origin access identity (legacy)
      domain_name = module.cdn-storage-bucket.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "cdn_storage_access_identity" # key in `origin_access_identities`
        # cloudfront_access_identity_path = "origin-access-identity/cloudfront/E5IGQAA1QO48Z" # external OAI resource
      }
    }
  }


  default_cache_behavior = {
    target_origin_id       = "cdn_storage"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    use_forwarded_values = false

    cache_policy_id            = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

  }

  ordered_cache_behavior = [
  ]


  custom_error_response = [
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/errors/404.html"
      }, {
      error_code         = 403
      response_code      = 403
      response_page_path = "/errors/403.html"
    }
  ]


}

data "aws_iam_policy_document" "cdn_storage_bucket_policy" {
  # Origin Access Identities
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.cdn-storage-bucket.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cdn-storage-cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.cdn-storage-bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cdn-storage-cloudfront.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cdn_storage_bucket_policy" {
  bucket = module.cdn-storage-bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.cdn_storage_bucket_policy.json
}

# module "cdn-storage-record" {
#   source  = "terraform-aws-modules/route53/aws//modules/records"
#   version = "~> 2.0"
#
#   zone_name = var.domain_zone_name
#
#   records = [
#     {
#       name = "cdn"
#       type = "A"
#       alias = {
#         name    = module.cdn-storage-cloudfront.cloudfront_distribution_domain_name
#         zone_id = module.cdn-storage-cloudfront.cloudfront_distribution_hosted_zone_id
#       }
#     },
#   ]
# }
