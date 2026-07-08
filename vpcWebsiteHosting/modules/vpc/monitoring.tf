# Store the Agent Config in SSM Parameter Store
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "/amazoncloudwatch-agent/ec2-config"
  type  = "String"
  value = file("${path.module}/../../agent-config.json")
  description = "CloudWatch Agent configuration for EC2 instances"
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "cloudwatch_alarms_topic" {
  name = "cloudwatch-alarms-topic"
  tags = var.tags
}

# Email Subscription for the SNS Topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

