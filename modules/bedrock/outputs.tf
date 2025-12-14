output "agent_id" {
  description = "ID of the Bedrock agent"
  value       = aws_bedrockagent_agent.this.id
}

output "agent_alias_id" {
  description = "ID of the Bedrock agent alias"
  value       = aws_bedrockagent_agent_alias.this.agent_alias_id
}