resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${local.name_prefix}/application"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/ec2/${local.name_prefix}/system"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "/aws/ec2/${local.name_prefix}/docker"
  retention_in_days = 14
}

resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${local.name_prefix}-application"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "ALB 5xx Errors"
          region = var.aws_region
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "ALB Target Response Time"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.app.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "RDS CPU Utilization"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "RDS Database Connections"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 6
        height = 6

        properties = {
          title  = "RDS Free Storage"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${local.name_prefix}-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.app.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU Utilization"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6

        properties = {
          title  = "RDS Database Connections"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage"
          region = var.aws_region
          stat   = "Average"
          period = 300

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      }
    ]
  })
}
