
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
locals {

  container_definition = merge({
    "name"      = var.name
    "image"     = var.image
    "essential" = true
    "cpu"       = var.container_cpu
    "memory"    = var.container_memory
    # "portMappings" = local.task_container_port_mappings
    # "stopTimeout"  = var.stop_timeout
    # "command"      = var.task_container_command
    # "environment"  = var.environment
    # "secrets"      = var.secrets
    # "MountPoints"  = local.task_container_mount_points
    # "linuxParameters"   = var.linux_parameters
    "readonlyRootFilesystem" = var.readonlyRootFilesystem
    # "logConfiguration" = {
    # "logDriver" = "awslogs"
    # "options"   = local.log_configuration_options
    # }
    "privileged" : var.privileged
  }, )
}
resource "aws_ecs_task_definition" "this" {
  family                   = join("-", [var.name, "scheduled", "task"]) # Naming our first task
  tags                     = var.tags
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  execution_role_arn       = aws_iam_role.scheduled_task_cloudwatch.arn
  task_role_arn            = aws_iam_role.scheduled_task_cloudwatch.arn
  dynamic "volume" {
    for_each = var.efs_volumes
    content {
      name = volume.value["name"]
      efs_volume_configuration {
        file_system_id     = volume.value["file_system_id"]
        root_directory     = volume.value["root_directory"]
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = volume.value["access_point_id"]
          iam             = "ENABLED"
        }
      }
    }

  }
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value["name"]
    }
  }
  container_definitions = jsonencode(concat([local.container_definition], var.sidecar_containers))
}

