locals {
  billing = "PROVISIONED"

  default_tags = {
    billing = local.billing
  }
}
