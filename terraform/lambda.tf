
# Create a role for the lambda function
resource "aws_iam_role" "lambda" {
    name               = "lambda_${var.application-name}"
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

# Create an IAM role policy that gives lambda access to the necessary resources
resource "aws_iam_role_policy" "lambda" {
  name = "lambda_${var.application-name}"
  role = "${aws_iam_role.lambda.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "arn:aws:s3:::gopro-lambda",
        "arn:aws:s3:::gopro-lambda/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "Stmt1472505058000",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GetKeyPolicy",
        "kms:ListAliases",
        "kms:ListKeys"
      ],
      "Resource": [
        "arn:aws:kms:us-west-2:786930545984:alias/lambda",
        "arn:aws:kms:us-west-2:786930545984:key/9dfb1e78-f788-4e5e-a581-947abf0a1bb8"
      ]
    }
  ]
}
EOF
}

# Attach the AWS managed AWSLambdaVPCAccessExecutionRole policy
resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role        = "${aws_iam_role.lambda.name}"
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMFullAccess" {
  role        = "${aws_iam_role.lambda.name}"
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# Create a 8 char random ID based on the app version
# This is so we can version the local zip files but
# still use the same filename in s3 and still trigger
# the s3 object upload
resource "random_id" "zipfile" {
  keepers = {
    version = "${md5(file("${path.module}/../src/index.js"))}"
    npm = "${md5(file("${path.module}/../src/package.json"))}"
  }

  byte_length = 8
}

resource "null_resource" "npm-install" {
  triggers {
    npm = "${random_id.zipfile.hex}"
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../src && npm install"
  }
}

# archive up the resources for the lambda function
# be sure any pip modules are also in the src directory
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../src/"
  output_path = "${path.module}/../${var.application-name}-${random_id.zipfile.hex}.zip"
  depends_on  = ["random_id.zipfile", "null_resource.npm-install"]
}

# Upload the zipfile to S3
resource "aws_s3_bucket_object" "lambda" {
  key         = "${var.application-name}/${var.application-name}.zip"
  bucket      = "gopro-lambda"
  source      = "${path.module}/../${var.application-name}-${random_id.zipfile.hex}.zip"
  etag        = "${md5(file("${path.module}/../${var.application-name}-${random_id.zipfile.hex}.zip"))}"
}

# Create the lambda function
# This also triggers an update when the s3 object is uploaded
resource "aws_lambda_function" "lambda" {
  s3_bucket         = "gopro-lambda"
  s3_key            = "${var.application-name}/${var.application-name}.zip"
  source_code_hash  = "${base64sha256(file("${path.module}/../${var.application-name}-${random_id.zipfile.hex}.zip"))}"
  function_name     = "${var.application-name}"
  role              = "${aws_iam_role.lambda.arn}"
  handler           = "index.handler"
  description       = "Lambda function ${var.application-name}"
  runtime           = "nodejs4.3"
  timeout           = "60"
  vpc_config {
    subnet_ids         = ["${split(",", module.aws.private-subnet-ids)}"]
    security_group_ids = ["${var.security_group_id}"]
  }
  kms_key_arn = "arn:aws:kms:us-west-2:786930545984:key/9dfb1e78-f788-4e5e-a581-947abf0a1bb8"
  environment {
    variables {
      CLIENT_ID = "AQECAHgQr5/PKIpeKY/LVjnp9n2Sma6LMaFOtMn8h8GiBFxxqQAAAHcwdQYJKoZIhvcNAQcGoGgwZgIBADBhBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDHXCVYme+IQtt5bUhQIBEIA0YhjNrWmjS/VAI3nQkB7kVOmG0BsippEC6MK6V/JbWgAZcnWZ6e1vtmh3oPDLZwpn7FDb0w=="
      CLIENT_SECRET = "AQECAHgQr5/PKIpeKY/LVjnp9n2Sma6LMaFOtMn8h8GiBFxxqQAAAH4wfAYJKoZIhvcNAQcGoG8wbQIBADBoBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDMa5vgo24+rSdCVCowIBEIA7vBN9k7WeLPl0d/9+ukl+2gKoqn0phaNnhITtnfuBx2ZO/50CMk84A+qTyGhtkl/SD72A1QgmTPJksfE="
      VERIFICATION_TOKEN = "AQECAHgQr5/PKIpeKY/LVjnp9n2Sma6LMaFOtMn8h8GiBFxxqQAAAHYwdAYJKoZIhvcNAQcGoGcwZQIBADBgBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDMfBOM1pbPpn7tFrIAIBEIAzKV8pboNnJHU3GB8gEf+gT8HNeKLVM2sA3Fa0KYuFiuJuBV1ep6bC5+18Oex4Th5z5CZs"
    }
  }
}
