# IAM Role for Bedrock Agent
resource "aws_iam_role" "this" {
  name = "${var.project_name}-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-bedrock-agent-role"
  })
}

resource "aws_iam_role_policy" "this" {
  name = "${var.project_name}-bedrock-agent-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:*::foundation-model/amazon.nova-lite-v1:0"
      }
    ]
  })
}

# Bedrock Agent
resource "aws_bedrockagent_agent" "this" {
  agent_name                   = "${var.project_name}-agent"
  agent_resource_role_arn      = aws_iam_role.this.arn
  foundation_model             = "amazon.nova-lite-v1:0"
  instruction                  = "You are a helpful assistant for KEPCO (Korea Electric Power Corporation). Answer questions about company policies, procedures, and technical information. Provide helpful and accurate responses based on your knowledge."
  skip_resource_in_use_check   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-bedrock-agent"
  })
}

# Agent Alias
resource "aws_bedrockagent_agent_alias" "this" {
  agent_alias_name = "live"
  agent_id         = aws_bedrockagent_agent.this.id
  description      = "Live alias for KEPCO chatbot agent"

  tags = merge(var.tags, {
    Name = "${var.project_name}-agent-alias"
  })
}