terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
  /*
  backend "s3" {
    bucket  = "terraform-statebucket"
    key     = "coderunner/poc/terraform.tfstate"
    region  = "ap-southeast-2"
    profile = "poc-account"
  }
  */
  required_version = ">= 0.13.3"
}

provider "aws" {
  profile = "uoa-sandbox"
  region  = "ap-southeast-2"
  ignore_tags {
    key_prefixes = ["Auto"]
  }
}

# Seriously, don't hardcode these.
# Recommended to use Parameter Store/Secrets Manager
# and retrieve when required
locals {
  app_name         = "CodeRunner"
  lifecycle_state  = "PoC"
  subnet_count     = length(var.private_subnets)
  ecs_cluster_name = "${local.app_name}-cluster"
  cw_log_group     = "/${local.app_name}/Containers/logs"
  db_name          = "moodle_db"
  db_user          = "moodle_user"
  db_password      = "dGh83yo4ZLOUFVAMapKIV"
  moodle_user      = "admin"
  moodle_pwd       = "09J*oJy@yTXT"
  common_tags = {
    "GitHubLink"      = "https://git.io/JUx2v"
    "Environment"     = "${local.lifecycle_state}"
}

resource "aws_cloudwatch_log_group" "global" {
  name              = local.cw_log_group
  retention_in_days = 7
}