# ----------------------------------
# S3 Bucket
# ----------------------------------
resource "aws_s3_bucket" "log_archive" {
  bucket        = "chris-log-archive-${random_id.id.hex}"
  force_destroy = true

  tags = {
    Name        = "log-archive"
    Environment = "production"
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------
# SSM Document
# ----------------------------------
resource "aws_ssm_document" "copy_logs_to_s3" {
  name          = "CopyLogsToS3"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Copy logs to S3 before instance termination",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "copyLogs",
        inputs = {
          runCommand = [
            "journalctl -o json-pretty > /tmp/logs.json",
            "aws s3 cp /tmp/logs.json s3://${aws_s3_bucket.log_archive.bucket}/logs/$(hostname)-$(date +%s).json"
          ]
        }
      }
    ]
  })
}

# ----------------------------------
# Lambda Function
# ----------------------------------
data "aws_iam_policy_document" "lambda_ssm_instance_terminate" {
  statement {
    actions = [
      "ssm:SendCommand",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_ssm_instance_terminate.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "log_copy_handler" {
  filename         = "lab1.zip"
  function_name    = "handleInstanceTerminateLogCopy"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lab1.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lab1.zip")
  timeout          = 60
  memory_size      = 128
  environment {
    variables = {
      SSM_DOCUMENT = aws_ssm_document.copy_logs_to_s3.name
    }
  }
}

# ----------------------------------
# Auto Scaling Group and Lifecycle Hook
# ----------------------------------
resource "aws_launch_template" "asg_template" {
  name_prefix   = "log-asg-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.linux.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }
}

resource "aws_autoscaling_group" "log_asg" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = module.vpc.public_subnets
  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "LogASGInstance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_lifecycle_hook" "terminate_hook" {
  name                   = "terminate-logs"
  autoscaling_group_name = aws_autoscaling_group.log_asg.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}

resource "aws_cloudwatch_event_rule" "asg_terminate" {
  name = "asg-terminate-lifecycle"
  event_pattern = jsonencode({
    source        = ["aws.autoscaling"],
    "detail-type" = ["EC2 Instance-terminate Lifecycle Action"]
  })
}

resource "aws_cloudwatch_event_target" "asg_to_lambda" {
  rule      = aws_cloudwatch_event_rule.asg_terminate.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.log_copy_handler.arn
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_copy_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_terminate.arn
}

resource "aws_iam_role" "ec2_ssm" {
  name = "ec2_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ec2_s3_put" {
  name        = "ec2-logs-upload-policy"
  description = "Allow EC2 to upload logs to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.log_archive.arn}/logs/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_put_attach" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = aws_iam_policy.ec2_s3_put.arn
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2_ssm_instance_profile"
  role = aws_iam_role.ec2_ssm.name
}
