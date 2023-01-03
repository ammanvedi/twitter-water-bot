provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }
  }

  backend "s3" {
    bucket = "twitterwaterbot"
    key    = "state"
  }
}



module "lambda" {
  source = "./lambda"

  lambda_function_name = "twitter_water_bot"
  iam_policy_name = "twitter_water_bot_policy"
  iam_role_name = "twitter_water_bot_role"

  twitter_consumer_key = var.twitter_consumer_key
  twitter_consumer_secret = var.twitter_consumer_secret
  twitter_access_token = var.twitter_access_token
  twitter_access_token_secret = var.twitter_access_token_secret

  # Do not change
  source_path = "${path.root}/../dist"
  dist_path = "${path.root}/../aws-dist"
  aws_region = var.aws_region
  providers = {
    aws = aws
  }
}