provider "aws" {
  region = var.aws_region
}

resource "aws_sns_topic" "rocket_project_sns_topic" {
  name = var.sns_topic_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}