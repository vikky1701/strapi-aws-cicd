provider "aws" {
  region = "us-east-2"
}

# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get Default Subnets (public subnets in default VPC)
data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Get individual subnet details to check availability zones
data "aws_subnet" "default_subnets" {
  for_each = toset(data.aws_subnets.default_public.ids)
  id       = each.value
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.150.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "strapi-private-subnet-1-vivek"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.180.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "strapi-private-subnet-2-vivek"
  }
}



# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "strapi-alb-sg-vivek-5"
  description = "Security group for Strapi ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-alb-sg-vivek-5"
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_sg" {
  name        = "strapi-ecs-sg-vivek"
  description = "Security group for Strapi ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-ecs-sg-vivek"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "strapi-rds-sg-vivek"
  description = "Security group for Strapi RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-rds-sg-vivek"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster-vivek"

  tags = {
    Name = "strapi-cluster-vivek"
  }
}

# Application Load Balancer (using only 2 subnets in different AZs)
resource "aws_lb" "strapi_alb" {
  name               = "strapi-alb-vivek"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  # Use only the first 2 subnets to ensure different AZs
  subnets = slice(data.aws_subnets.default_public.ids, 0, 2)

  enable_deletion_protection = false

  tags = {
    Name = "strapi-alb-vivek"
  }
}

# Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name        = "strapi-tg-vivek-4"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 30
    interval            = 60
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "strapi-tg-vivek-4"
  }
}

# ALB Listener
resource "aws_lb_listener" "strapi_listener" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

# Create a custom DB parameter group for SSL
resource "aws_db_parameter_group" "strapi_postgres_params" {
  family = "postgres15"
  name   = "strapi-postgres-params-vivek-4"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "strapi-postgres-params-vivek-4"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "strapi-db-subnet-group-vivek-2"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "strapi-db-subnet-group-vivek-2"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "strapi_postgres" {
  identifier                = "strapi-postgres-db-vivek"
  engine                    = "postgres"
  engine_version            = "15.8"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  storage_type              = "gp2"
  db_name                   = var.db_name
  username                  = var.db_user
  password                  = var.db_password
  port                      = 5432
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
  db_subnet_group_name      = aws_db_subnet_group.strapi_db_subnet_group.name
  parameter_group_name      = aws_db_parameter_group.strapi_postgres_params.name
  publicly_accessible       = false
  skip_final_snapshot       = true
  backup_retention_period   = 0
  storage_encrypted         = true
  
  # Apply changes immediately
  apply_immediately = true

  tags = {
    Name = "strapi-postgres-db-vivek"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi-task-vivek-2"
  retention_in_days = 7

  tags = {
    Name = "strapi-logs-vivek"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task-vivek"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::607700977843:role/ecs-task-execution-role"
  task_role_arn            = "arn:aws:iam::607700977843:role/ecs-task-execution-role"

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.ecr_image_url
      essential = true
      
      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DATABASE_CLIENT"
          value = "postgres"
        },
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.strapi_postgres.address
        },
        {
          name  = "DATABASE_PORT"
          value = "5432"
        },
        {
          name  = "DATABASE_NAME"
          value = var.db_name
        },
        {
          name  = "DATABASE_USERNAME"
          value = var.db_user
        },
        {
          name  = "DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DATABASE_SSL"
          value = "true"
        },
        {
          name  = "DATABASE_SSL_REJECT_UNAUTHORIZED"
          value = "false"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "HOST"
          value = "0.0.0.0"
        },
        {
          name  = "PORT"
          value = "1337"
        },
        {
          name  = "APP_KEYS"
          value = "b1982b2a6696cba71779ae03984447491d8853791430246d8fbe6ca31708d851,338f5347118e9363e0d3152bbd65f28d1f20a7e34a03015b5505b1d149ad224c"
        },
        {
          name  = "API_TOKEN_SALT"
          value = "afac994bd91eead26299e380a909c461"
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = "4c366406e1428933ffe12b5e057fb3e8"
        },
        {
          name  = "TRANSFER_TOKEN_SALT"
          value = "0c7ab253f69e75c7880b358a4ca500ee"
        },
        {
          name  = "JWT_SECRET"
          value = "b2f46cc28d098da58ea62e5e5ab3737c"
        }
        
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.strapi_logs.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:1337/ || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "strapi-task-vivek"
  }
}

# ECS Service
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service-vivek"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = slice(data.aws_subnets.default_public.ids, 0, 2)
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [
    aws_lb_listener.strapi_listener,
    aws_db_instance.strapi_postgres
  ]

  tags = {
    Name = "strapi-service-vivek"
  }
}