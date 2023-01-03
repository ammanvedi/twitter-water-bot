variable "lambda_function_name" {
  type = string
  description = "what to call your lambda function in aws"
}

variable "iam_role_name" {
  type = string
  description = "what to call your lambda function role in aws"
}

variable "iam_policy_name" {
  type = string
  description = "what to call your lambda function policy in aws"
}

variable "source_path" {
  type = string
  description = "the directory of the built source files"
}

variable "dist_path" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "twitter_consumer_key" {
  type = string
}

variable "twitter_consumer_secret" {
  type = string
}

variable "twitter_access_token" {
  type = string
}

variable "twitter_access_token_secret" {
  type = string
}