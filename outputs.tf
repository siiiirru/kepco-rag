output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = module.ec2.public_ip
}

output "streamlit_url" {
  description = "Streamlit application URL via ALB"
  value       = "http://${module.alb.dns_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.dns_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "bedrock_agent_id" {
  description = "Bedrock Agent ID"
  value       = module.bedrock.agent_id
}

output "bedrock_agent_alias_id" {
  description = "Bedrock Agent Alias ID"
  value       = module.bedrock.agent_alias_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for application logs"
  value       = "/aws/ec2/kepco-chatbot"
}

output "ssm_connect_command" {
  description = "SSM connect command"
  value       = "aws ssm start-session --target ${module.ec2.instance_id} --region us-east-1"
}
