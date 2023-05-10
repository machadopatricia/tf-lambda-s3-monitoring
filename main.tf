terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "read_bucket_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:Get*","s3:List*"]
    resources = ["arn:aws:s3:::bucket-para-lambda-cross-account"]
  }
}

resource "aws_iam_policy" "read_bucket_policy" {
  name        = "ReadBucketPolicy"
  policy      = data.aws_iam_policy_document.read_bucket_policy_doc.json
}

resource "aws_iam_role" "lambda_s3_role" {
  name               = "LambdaReadS3Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attachment_lambda_basic_managed" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attachment_read_bucket_policy" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = aws_iam_policy.read_bucket_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_s3_role.arn
  runtime          = var.lambda_function_runtime
  handler          = var.lambda_function_handler
  publish          = true
  filename = "lambda-monitoring-function.zip"
  source_code_hash = filebase64sha256("lambda-monitoring-function.zip")
}

resource "aws_cloudwatch_event_rule" "every_5_minutes" {
  name        = "lambda-monitoring-rule"
  description = "Trigger Lambda everyday"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.every_5_minutes.name
  target_id = "SendToMonitoringS3Lambda"
  arn       = aws_lambda_function.lambda_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_5_minutes.arn
}