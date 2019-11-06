# Create a new load balancer

module "vpc-west" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "2.9.0"
  name               = "${var.prefix}-palacearcade"
  cidr               = "10.0.0.0/16"
  azs                = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  enable_vpn_gateway = false
}

resource "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = "${module.vpc-west.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 4.0"

  logging_enabled = false

  load_balancer_name       = "${var.prefix}-palacearcade"
  security_groups          = ["${aws_security_group.allow_http.id}"]
  subnets                  = "${module.vpc-west.public_subnets}"
  vpc_id                   = "${module.vpc-west.vpc_id}"
  http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count = "1"
  target_groups            = "${list(map("name", "fargate", "target_type", "ip", "backend_protocol", "HTTP", "backend_port", "80"))}"
  target_groups_count      = "1"
}
