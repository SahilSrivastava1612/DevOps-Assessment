terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_DEV_TF_STATE_BUCKET"
    key            = "devops-assessment/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "REPLACE_WITH_DEV_TF_LOCK_TABLE"
    encrypt        = true
  }
}
