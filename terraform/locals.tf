locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  container_name = "${local.name_prefix}-container"
}