output "app_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.kepco_chatbot.name
}

output "system_log_group_name" {
  description = "Name of the kepco_userdata log group"
  value       = aws_cloudwatch_log_group.kepco_userdata.name
}