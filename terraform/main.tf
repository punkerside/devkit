resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-${var.service}"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
	Name = "${var.project}-${var.env}-${var.service}"
  }
}