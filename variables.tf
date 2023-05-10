variable "region" {
  type    = string
  default = "us-east-1"
}

#### LAMBDA VARIABLES ####

variable "lambda_function_name" {
  type    = string
  default = "lambda-s3-monitoring"
}

variable "lambda_function_runtime" {
  type    = string
  default = "python3.8"
}

variable "lambda_function_handler" {
  type    = string
  default = "lambda-monitoring-function.lambda_handler"
}