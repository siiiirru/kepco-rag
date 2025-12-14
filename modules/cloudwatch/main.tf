resource "aws_cloudwatch_log_group" "kepco_chatbot" {
  name              = "/aws/ec2/kepco-chatbot"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-logs"
  })
}

resource "aws_cloudwatch_log_group" "kepco_userdata" {
  name              = "/aws/ec2/kepco-userdata"
  retention_in_days = 3

  tags = merge(var.tags, {
    Name = "${var.project_name}-userdata-logs"
  })
}
