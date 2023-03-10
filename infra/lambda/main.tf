terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }
  }
}

locals {
  source_archive = "${var.dist_path}/bundle.zip"
}


resource "aws_iam_role" "lambda_role" {
  name   = var.iam_role_name
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = var.iam_policy_name
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${var.source_path}/"
  output_path = local.source_archive
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = local.source_archive
  function_name                  = var.lambda_function_name
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.handler"
  runtime                        = "nodejs18.x"
  source_code_hash               = "${base64sha256(filebase64(local.source_archive))}"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  environment {
    variables = {
      TF_VAR_twitter_consumer_key = var.twitter_consumer_key
      TF_VAR_twitter_consumer_secret = var.twitter_consumer_secret
      TF_VAR_twitter_access_token = var.twitter_access_token
      TF_VAR_twitter_access_token_secret = var.twitter_access_token_secret
    }
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name = "schedule"
  description = "Schedule for Lambda Function"
  schedule_expression = "rate(3 hours)"
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  target_id = "processing_lambda"
  arn = aws_lambda_function.terraform_lambda_func.arn
  depends_on = [aws_lambda_function.terraform_lambda_func, aws_cloudwatch_event_rule.schedule]
}


resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.schedule.arn
  depends_on = [aws_lambda_function.terraform_lambda_func, aws_cloudwatch_event_rule.schedule]
}