
# Include the AWS module -- This contains "shared" infra attributes
module "aws" {
  source = "../../devops-tools/terraform/modules/aws"

  environment   = "${var.environment}"
}

# initialize the aws provider using the gopro-platform AWS_PROFILE
provider "aws" {
  region = "${var.aws-region}"
  profile = "${var.aws-profile}"
  allowed_account_ids = ["${module.aws.account-id}"]
}
