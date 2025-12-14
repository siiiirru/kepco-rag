# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User Data Script
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    bedrock_agent_id       = var.bedrock_agent_id
    bedrock_agent_alias_id = var.bedrock_agent_alias_id
  })
}


# EC2 Instance
resource "aws_instance" "this" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = "t3.micro"  # 프리티어
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = var.security_group_ids
  iam_instance_profile    = var.iam_instance_profile
  disable_api_termination = false
  
  user_data = local.user_data
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 30  # Amazon Linux 2023 최소 요구사항
    encrypted   = false  # 비용 절약
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ec2"
  })
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this.id
  port             = 8501
}