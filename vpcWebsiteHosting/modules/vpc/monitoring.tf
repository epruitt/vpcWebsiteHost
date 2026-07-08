# Store the Agent Config in SSM Parameter Store
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "/amazoncloudwatch-agent/ec2-config"
  type  = "String"
  value = file("${path.module}/../../agent-config.json")
  description = "CloudWatch Agent configuration for EC2 instances"
}

