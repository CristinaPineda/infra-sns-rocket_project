# sns.tf 
resource "aws_sns_topic" "rocket_project_sns_topic" {
  name = var.sns_topic_name

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

# Recurso 1: IAM Role que o SNS assumirá
resource "aws_iam_role" "sns_delivery_logging_role" {
  name = "sns-delivery-logging-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Recurso 2: IAM Policy que permite o SNS escrever no CloudWatch Logs
resource "aws_iam_role_policy" "sns_delivery_logging_policy" {
  name = "sns-delivery-logging-policy-${var.environment}"
  role = aws_iam_role.sns_delivery_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/sns/*"
      }
    ]
  })
}