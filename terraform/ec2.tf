data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${local.name_prefix}-key"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = aws_key_pair.ec2.key_name
  associate_public_ip_address = false
  user_data_replace_on_change = true

  user_data = <<-EOF_USERDATA
              #!/bin/bash
              set -e

              dnf update -y
              dnf install -y docker awscli

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ec2-user

              mkdir -p /opt/devops-assignment
              chown ec2-user:ec2-user /opt/devops-assignment

              # Install Amazon CloudWatch Agent.
              dnf install -y amazon-cloudwatch-agent

              mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CW_CONFIG'
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "run_as_user": "root"
                },
                "metrics": {
                  "namespace": "DevOpsAssignment/EC2",
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}",
                    "InstanceType": "$${aws:InstanceType}"
                  },
                  "metrics_collected": {
                    "mem": {
                      "measurement": [
                        "mem_used_percent"
                      ],
                      "metrics_collection_interval": 60
                    },
                    "disk": {
                      "measurement": [
                        "used_percent"
                      ],
                      "resources": [
                        "/"
                      ],
                      "metrics_collection_interval": 60
                    }
                  }
                },
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/messages",
                          "log_group_name": "/aws/ec2/${local.name_prefix}/system",
                          "log_stream_name": "{instance_id}/messages"
                        },
                        {
                          "file_path": "/var/log/secure",
                          "log_group_name": "/aws/ec2/${local.name_prefix}/system",
                          "log_stream_name": "{instance_id}/secure"
                        },
                        {
                          "file_path": "/var/log/cloud-init-output.log",
                          "log_group_name": "/aws/ec2/${local.name_prefix}/system",
                          "log_stream_name": "{instance_id}/cloud-init-output"
                        },
                        {
                          "file_path": "/var/lib/docker/containers/*/*.log",
                          "log_group_name": "/aws/ec2/${local.name_prefix}/docker",
                          "log_stream_name": "{instance_id}/docker"
                        }
                      ]
                    }
                  }
                }
              }
              CW_CONFIG

              systemctl enable amazon-cloudwatch-agent

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
                -s
              EOF_USERDATA

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-app"
  }
}
