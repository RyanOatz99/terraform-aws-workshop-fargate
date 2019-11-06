provider "aws" {
  version = "~> 2.0"
  region  = "us-west-2"
}

resource "aws_ecs_cluster" "palacearcade" {
  name = "${var.prefix}-palacearcade"
}

resource "aws_ecs_task_definition" "palacearcade" {
  family                   = "service"
  container_definitions    = "[ { \"name\": \"palacearcade\", \"image\": \"scarolan\\/palacearcade:latest\", \"cpu\": 128, \"memory\": 128, \"essential\": true, \"portMappings\": [ { \"containerPort\": 80, \"hostPort\": 80 } ] } ]"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "palacearcade" {
  name            = "${var.prefix}-palacearcade"
  cluster         = "${aws_ecs_cluster.palacearcade.id}"
  task_definition = "${aws_ecs_task_definition.palacearcade.arn}"

  launch_type = "FARGATE"

  desired_count = 3

  network_configuration {
    assign_public_ip = true
    security_groups  = ["${aws_security_group.allow_http.id}"]
    subnets          = "${module.vpc-west.public_subnets}"
  }

  load_balancer {
    target_group_arn = "${module.alb.target_group_arns[0]}"
    container_name   = "palacearcade"
    container_port   = 80
  }
}