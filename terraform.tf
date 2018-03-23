
terraform {
  required_version = ">= 0.11.4"
  backend "s3" {
    bucket = "clicks-tf-state"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "clicks-tf-state"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
  region     = "${var.region}"
}
