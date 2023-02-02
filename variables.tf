variable "name" {
  description = "name, to be used as prefix for all resource names"
  type        = string
  default     = "bb"
}

variable "cluster_arn" {
  description = "name, to be used as prefix for all resource names"
  type        = string
  default     = "arn:aws:ecs:us-west-2:497286016891:cluster/bb-qa-cluster"
}

variable "cicd_enabled" {
  default     = true
  description = "Set to `false` to prevent the module from creating any resources"
  type        = bool
}
variable "task_definition_arn" {
  description = "name, to be used as prefix for all resource names"
  type        = string
  default     = "arn:aws:ecs:us-west-2:497286016891:task-definition/kk-test:5"
}
variable "schedule_expression" {
  description = "(Optional) The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes). At least one of event_rule_schedule_expression or event_rule_event_pattern is required. Can only be used on the default event bus."
  default     = "cron(0 20 * * ? *)"
}
variable "assign_public_ip" {
  description = "Enables container insights if true"
  type        = bool
  default     = false
}
variable "tags" {
  default     = {}
  description = "A map of tags to add to all resources"
  type        = map(string)
}


variable "security_groups" {
  description = "The security groups to attach to the ecs. e.g. [\"sg-edcd9784\",\"sg-edcd9785\"]"
  type        = list(string)
  default     = ["sg-0ddc56abba3b2c072"]
}

variable "subnets" {
  description = "A list of subnets to associate with the ecs . e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f']"
  type        = list(string)
  default     = ["subnet-0ced6ea0387789f95", "subnet-0e2e9ced13c991a3e"]
}

variable "volumes" {
  description = "List of volume"
  type        = list(any)
  default     = []
}

variable "efs_volumes" {
  description = "Volumes definitions"
  default     = []
  type = list(object({
    name            = string
    file_system_id  = string
    root_directory  = string
    mount_point     = string
    readOnly        = bool
    access_point_id = string
  }))
}


variable "container_cpu" {
  type        = number
  default     = 256
  description = "How much CPU to give the container. 1024 is 1 CPU"
}

variable "container_memory" {
  type        = number
  default     = 512
  description = "How much memory in megabytes to give the container"
}


variable "privileged" {
  description = "When this parameter is true, the container is given elevated privileges on the host container instance"
  default     = false
  type        = bool
}

variable "readonlyRootFilesystem" {
  default     = false
  description = "When this parameter is true, the container is given read-only access to its root file system"
}

variable "sidecar_containers" {
  description = "List of sidecar containers"
  type        = list(any)
  default     = []
}


## CodeBuild

variable "compute_type" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "IMAGE_REPO_NAME" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "aws_account_id" {
  default = ""
}

variable "region" {
  default = "us-west-2"
}

variable "SERVICE_PORT" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "MEMORY_RESV" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "DEPLOY" {
  description = "The resource name."
  type        = string
  default     = ""
}

## CodePipeline


variable "repositoryname" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "branchname" {
  description = "The resource name."
  type        = string
  default     = null
}