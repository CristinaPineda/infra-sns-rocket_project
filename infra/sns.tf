# sns.tf 
resource "aws_sns_topic" "rocket_project_sns_topic" {
  name = var.sns_topic_name

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------------------------------
# NOVO RECURSO: Configuração de Logging do Tópico
# Este recurso é OBRIGATÓRIO para configurar o Delivery Status Logging.
# --------------------------------------------------------------------------
resource "aws_sns_topic_logging" "rocket_project_sns_logging" {
  # O ARN do Tópico SNS ao qual aplicamos as regras
  topic_arn = aws_sns_topic.rocket_project_sns_topic.arn

  # O Protocolo que queremos monitorar (O seu destino é o SQS)
  protocol = "sqs"

  # Configuração de SUCCESSO
  success_feedback_role_arn     = aws_iam_role.sns_delivery_logging_role.arn
  success_feedback_sample_rate  = 100 # 100% de amostragem

  # Configuração de FALHA
  failure_feedback_role_arn     = aws_iam_role.sns_delivery_logging_role.arn
}