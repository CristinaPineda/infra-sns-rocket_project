output "sns_topic_arn" {
  description = "The ARN of the SNS topic."
  value       = aws_sns_topic.rocket_project_sns_topic.arn
}

output "sns_topic_name" {
  description = "The name of the SNS topic."
  value       = aws_sns_topic.rocket_project_sns_topic.name
}