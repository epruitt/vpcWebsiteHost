# Store the Agent Config in SSM Parameter Store
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "/amazoncloudwatch-agent/ec2-config"
  type        = "String"
  value       = file("${path.module}/../../agent-config.json")
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

# EC2 Status Check Failed (Free, No Agent Required)
# Triggers if either system or instance status checks fail for 2 consecutive minutes
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "omnifood-ec2-status-check"
  alarm_description   = "EC2 instance failed status check (hardware or network issue)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.omnifood_alerts.arn]
  ok_actions          = [aws_sns_topic.omnifood_alerts.arn]

  dimensions = {
    InstanceId = var.instance_id # Pass this variable from root/module caller
  }
}

# High CPU Utilization (Free, No Agent Required)
# Triggers if CPU > 80% for 3 consecutive 5-minute periods
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "omnifood-ec2-high-cpu"
  alarm_description   = "EC2 CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms_topic.arn]
  ok_actions          = [aws_sns_topic.cloudwatch_alarms_topic.arn]

  dimensions = {
    InstanceId = var.instance_id
  }
}

# High Memory Utilization (Custom, Requires Agent)
# Triggers if mem_used_percent > 90% for 2 consecutive 1-minute periods
# Validates that the CloudWatch Agent is running and sending data to 'CWAgent' namespace
resource "aws_cloudwatch_metric_alarm" "ec2_high_memory" {
  alarm_name          = "omnifood-ec2-high-memory"
  alarm_description   = "EC2 Memory utilization exceeds 90% (Agent validation)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms_topic.arn]
  ok_actions          = [aws_sns_topic.cloudwatch_alarms_topic.arn]

  # Treat missing data as breaching to catch agent failures
  treat_missing_data = "breaching"

  dimensions = {
    InstanceId = var.instance_id
  }
}

# ALB Unhealthy Host Count (Critical "Site Down" Signal)
# Triggers immediately if ANY target in the group is unhealthy
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "omnifood-alb-unhealthy-hosts"
  alarm_description   = "ALB Target Group has unhealthy hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.omnifood_alerts.arn]
  ok_actions          = [aws_sns_topic.omnifood_alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix          # Pass alb_arn_suffix (e.g., "app/my-alb/12345")
    TargetGroup  = var.target_group_arn_suffix # Pass target_group_arn_suffix
  }
}