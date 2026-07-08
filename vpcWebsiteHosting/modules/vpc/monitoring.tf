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

#Cloudwatch Dashboard for EC2 and ALB Monitoring
resource "aws_cloudwatch_dashboard" "omnifood_main" {
  dashboard_name = "omnifood-main-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # --- Header ---
      {
        type = "text"
        x    = 0
        y    = 0
        width = 24
        height = 1
        properties = {
          markdown = "# Omnifood Infrastructure Overview\nReal-time monitoring using **Free Standard Metrics** (No Agent Required)"
        }
      },

      # Alarm Status Widget (At-a-glance health)
      {
        type = "alarm"
        x    = 0
        y    = 1
        width = 24
        height = 2
        properties = {
          title = "Current Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.ec2_status_check.arn,
            aws_cloudwatch_metric_alarm.ec2_high_cpu.arn,
            aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn,
            aws_cloudwatch_metric_alarm.alb_target_5xx.arn
          ]
        }
      },

      # Widget 1: EC2 Health (Free Metrics)
      {
        type = "metric"
        x    = 0
        y    = 3
        width = 12
        height = 6
        properties = {
          title = "EC2 Health: CPU & Status Checks"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id, { stat = "Average", label = "CPU %" }],
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.instance_id, { stat = "Maximum", label = "Status Failures", color = "#d62728" }]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "Percent"
            }
          }
        }
      },

      # Widget 2: Network & Disk I/O (Free Metrics Replacement)
      {
        type = "metric"
        x    = 12
        y    = 3
        width = 12
        height = 6
        properties = {
          title = "EC2 I/O: Network & Disk Operations"
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id, { stat = "Average", label = "Net In (Bytes)", color = "#1f77b4" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.instance_id, { stat = "Average", label = "Net Out (Bytes)", color = "#2ca02c" }],
            ["AWS/EC2", "DiskReadOps", "InstanceId", var.instance_id, { stat = "Average", label = "Disk Read Ops", color = "#ff7f0e" }],
            ["AWS/EC2", "DiskWriteOps", "InstanceId", var.instance_id, { stat = "Average", label = "Disk Write Ops", color = "#d62728" }]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      },

      # Section Header: Load Balancer
      {
        type = "text"
        x    = 0
        y    = 9
        width = 24
        height = 1
        properties = {
          markdown = "### Application Load Balancer Performance"
        }
      },

      # Widget 3: ALB Traffic
      {
        type = "metric"
        x    = 0
        y    = 10
        width = 12
        height = 6
        properties = {
          title = "ALB Traffic: Requests & Latency"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "Requests" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "Average", label = "Avg Latency (s)" }]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      },

      # Widget 4: ALB Health
      {
        type = "metric"
        x    = 12
        y    = 10
        width = 12
        height = 6
        properties = {
          title = "ALB Health: Host Count"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Average", label = "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Maximum", label = "Unhealthy", color = "#d62728" }]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
          yAxis = {
            left = {
              min = 0
              label = "Hosts"
            }
          }
        }
      },

      # Widget 5: Errors 
      {
        type = "metric"
        x    = 0
        y    = 16
        width = 24
        height = 6
        properties = {
          title = "Error Rates: Target & ELB 5xx"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "Target 5xx" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "ELB 5xx", color = "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      }
    ]
  })
}   