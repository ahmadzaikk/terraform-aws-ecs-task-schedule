
data "aws_iam_policy_document" "assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    sid    = "AllowECRLogging"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecs:DescribeClusters",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:List*",
      "secretsmanager:GetResourcePolicy"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.name}_ecsTaskscheduleExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs.json
}

resource "aws_iam_role_policy" "execution_role" {
  role   = aws_iam_role.execution_role.name
  policy = data.aws_iam_policy_document.execution_role.json
}
## Cloudwatch event role

resource "aws_iam_role" "scheduled_task_cloudwatch" {
  name               = "${var.name}_cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.scheduled-task-cloudwatch-assume-role-policy.json
}


data "aws_iam_policy_document" "scheduled-task-cloudwatch-assume-role-policy" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "role" {
  role       = join("", aws_iam_role.scheduled_task_cloudwatch.*.name)
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

### Task Definition
resource "aws_ecs_task_definition" "default" {
  count = var.enabled ? 1 : 0
  family = join("-", [var.name, "task"]) # Naming our first task
  execution_role_arn = aws_iam_role.execution_role.arn
  task_role_arn  = aws_iam_role.execution_role.arn
  container_definitions = var.container_definitions
  cpu = var.cpu
  memory = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  tags = var.tags
}

## Cloudwatch event
resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name                = join("-", [var.name, "schedule", "task"])
  description         = "Run task at a scheduled time"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  target_id = "scheduled-ecs-target"
  rule      = aws_cloudwatch_event_rule.scheduled_task.name
  arn       = var.cluster_arn
  role_arn = aws_iam_role.scheduled_task_cloudwatch.arn

  ecs_target {
    task_count = 1
    task_definition_arn = join("", aws_ecs_task_definition.default.*.arn)
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = var.subnets
      assign_public_ip = var.assign_public_ip
      security_groups  = var.security_groups
    }
  }
}



