# --- ecs.tf (ECS Fargate Cluster, Task Definition y Service) ---

# 1. ECS Cluster
# Un grupo lógico donde se ejecutarán las tareas de Fargate
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    Name = "main-ecs-cluster"
  }
}

# 2. ECS Task Definition (Define la imagen Docker y los recursos)
resource "aws_ecs_task_definition" "spring_boot_task" {
  family                   = "${var.project_name}-spring-boot-task"
  network_mode             = "awsvpc" # Necesario para Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB

  # Utiliza el rol IAM para la ejecución (logs, pulling de ECR) y el de la tarea (acceso a Secrets, etc)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "spring-boot-app"
      image     = "${aws_ecr_repository.spring_boot_repo.repository_url}:latest" # URL de ECR creada en ecr.tf
      cpu       = 1024
      memory    = 2048
      essential = true

      portMappings = [
        {
          containerPort = 8080 # Puerto de la aplicación Spring Boot
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      # VARIABLES DE ENTORNO: Conexión segura a RDS a través de Secrets Manager
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn # ARN del secreto en secrets.tf
        }
      ]

      environment = [
        # Variables para Spring Boot y JDBC
        { name = "SPRING_DATASOURCE_USERNAME", value = "admin" },
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_db_instance.mysql_db.address}:3306/${aws_db_instance.mysql_db.db_name}" },
        # La contraseña la toma automáticamente de DB_PASSWORD (Secrets)
        { name = "SERVER_PORT", value = "8080" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/spring-boot-app"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 3. ECS Service (Mantiene el número de tareas y las conecta al Load Balancer)
resource "aws_ecs_service" "spring_boot_service" {
  name            = "${var.project_name}-spring-boot-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.spring_boot_task.arn
  desired_count   = 2 # Alta disponibilidad: 2 tareas en 2 AZs (tu diagrama)
  launch_type     = "FARGATE"

  # Mapeo al Target Group del Load Balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.spring_boot_tg.arn
    container_name   = "spring-boot-app"
    container_port   = 8080
  }

  network_configuration {
    security_groups = [aws_security_group.fargate.id] # SG-Fargate
    subnets         = [aws_subnet.private_app[0].id, aws_subnet.private_app[1].id] # Subredes Privadas (app-az1, app-az2)
    assign_public_ip = false
  }

  # Configuración de despliegue gradual
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_listener.http, # <--- ¡ESTO ES LO QUE FALTABA!
    aws_iam_role_policy_attachment.ecs_task_exec_policy,
    aws_iam_role_policy_attachment.ecs_task_policy_attach,
  ]
}

# 4. CloudWatch Log Group (Necesario para los logs de ECS)
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/spring-boot-app"
  retention_in_days = 7
}