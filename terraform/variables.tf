
variable "application-name" {
  description = "The name of the application"
}

variable "module-name" {
  default = ""
  description = "The name of the lambda module if different from application-name"
}

variable "environment" {
  description = "The environment of the application [qa, staging, prod, infra]"
}

variable "handler-name" {
  description = "The name of the function that servers as the lambda handler"
}

variable "security_group_id" {
  description = "The security group id for the lambda function"
}

variable "aws-profile" {
  default = "gopro-platform"
  description = "The AWS profile to use from ~/.aws/credentials"
}

variable "aws-region" {
  default = "us-west-2"
  description = "The AWS region to connect to"
}
