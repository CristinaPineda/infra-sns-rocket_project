resource "aws_sns_topic" "rocket_project_sns_topic" {
  name = var.sns_topic_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  # --- Configuração de Logging de Entrega ---
  # Define o ARN da Role para logs de SUCESSO para todos os protocolos
  application_success_feedback_role_arn = aws_iam_role.sns_delivery_logging_role.arn
  lambda_success_feedback_role_arn      = aws_iam_role.sns_delivery_logging_role.arn
  sqs_success_feedback_role_arn         = aws_iam_role.sns_delivery_logging_role.arn
  http_success_feedback_role_arn        = aws_iam_role.sns_delivery_logging_role.arn

  # Define a taxa de amostragem de sucesso para 100%
  application_success_feedback_sample_rate = 100
  lambda_success_feedback_sample_rate      = 100
  sqs_success_feedback_sample_rate         = 100
  http_success_feedback_sample_rate        = 100

  # Define o ARN da Role para logs de FALHA para todos os protocolos
  application_failure_feedback_role_arn = aws_iam_role.sns_delivery_logging_role.arn
  lambda_failure_feedback_role_arn      = aws_iam_role.sns_delivery_logging_role.arn
  sqs_failure_feedback_role_arn         = aws_iam_role.sns_delivery_logging_role.arn
  http_failure_feedback_role_arn        = aws_iam_role.sns_delivery_logging_role.arn
  # ------------------------------------------

  # FORÇA A DEPENDÊNCIA: Garante que a Role, a Policy e o recurso de espera (wait_for_iam_propagation)
  # sejam totalmente criados e executados antes de configurar o tópico.
  depends_on = [
    aws_iam_role.sns_delivery_logging_role,
    aws_iam_role_policy.sns_delivery_logging_policy,
    null_resource.wait_for_iam_propagation # Nova dependência para espera
  ]
}

# Recurso auxiliar para forçar uma espera e mitigar a propagação lenta do IAM.
resource "null_resource" "wait_for_iam_propagation" {
  # O trigger garante que este recurso só execute após a política ser criada
  # e qualquer mudança na política force a reexecução.
  triggers = {
    policy_id = aws_iam_role_policy.sns_delivery_logging_policy.id
  }

  provisioner "local-exec" {
    command = "sleep 10" # Espera 10 segundos para dar tempo à AWS propagar a Role de Logging.
  }

  depends_on = [
    aws_iam_role_policy.sns_delivery_logging_policy
  ]
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