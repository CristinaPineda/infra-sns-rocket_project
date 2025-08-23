# sns.tf

resource "aws_sns_topic" "rocket_project_sns_topic" {
  name = var.sns_topic_name

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

# aws_sns_topic.rocket_project_sns_topic já está definido

# 1. Cria um grupo de logs no CloudWatch para as entregas do SNS
resource "aws_cloudwatch_log_group" "sns_delivery_logs" {
  name = "/aws/sns/deliveries/${var.sns_topic_name}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# 2. Cria uma política de IAM para permitir que o SNS escreva logs
resource "aws_iam_role" "sns_cloudwatch_logging_role" {
  name = "${var.project_name}-${var.environment}-sns-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "sns_cloudwatch_logging_policy" {
  name = "${var.project_name}-${var.environment}-sns-logging-policy"
  role = aws_iam_role.sns_cloudwatch_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sns/*"
      }
    ]
  })
}

# 3. Conecta o SNS ao CloudWatch usando o role e o log group
resource "aws_sns_topic_logging" "sns_topic_logging_config" {
  topic_arn = aws_sns_topic.rocket_project_sns_topic.arn
  iam_role_arn = aws_iam_role.sns_cloudwatch_logging_role.arn

  success_feedback_role_arn = aws_iam_role.sns_cloudwatch_logging_role.arn
  success_feedback_sample_rate = 100
  failure_feedback_role_arn = aws_iam_role.sns_cloudwatch_logging_role.arn
}

# Adicione a permissão ao SNS para assumir a role
resource "aws_iam_role_policy_attachment" "sns_cloudwatch_logging_attachment" {
  role       = aws_iam_role.sns_cloudwatch_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSNSLogsDelivery"
}