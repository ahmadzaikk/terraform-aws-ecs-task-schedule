
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
    task_definition_arn = aws_ecs_task_definition.this.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = var.subnets
      assign_public_ip = var.assign_public_ip
      security_groups  = var.security_groups
    }
  }
}


### Task Definition
resource "aws_ecs_task_definition" "default" {
  count = var.enabled ? 1 : 0
  family = join("-", [var.name, "task"]) # Naming our first task
  execution_role_arn = aws_iam_role.execution_role.arn
  container_definitions = var.container_definitions
  cpu = var.cpu
  memory = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  tags = var.tags
}

