data "aws_region" "main" {}
data "aws_caller_identity" "main" {}

data "aws_route53_zone" "main" {
  name         = "${var.domain}."
  private_zone = false
}