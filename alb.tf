# --- alb.tf (Application Load Balancer) ---

# 1. Crea el Application Load Balancer (ALB)
resource "aws_lb" "application_lb" {
  name               = "${var.project_name}-alb"
  internal           = false # Público (facing Internet)
  load_balancer_type = "application"

  # Se coloca en las dos subredes públicas (asumiendo que las subredes están nombradas 'public_a' y 'public_b' o se accede por índice)
  # Usaremos los índices 0 y 1 de las subredes públicas definidas en subnets.tf
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  # Asigna el Security Group SG-ALB creado en security.tf
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = false # CÁMBIALO a 'true' en producción

  tags = { Name = "application-load-balancer" }
}

# 2. Crea el Target Group (Grupo de Destinos) para Fargate
# Aquí es donde se registran las tareas de ECS Fargate
resource "aws_lb_target_group" "spring_boot_tg" {
  name        = "${var.project_name}-tg-spring-boot"
  port        = 8080 # El puerto que está escuchando la aplicación Spring Boot
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Necesario para ECS Fargate

  # Configuración de Health Check para verificar la salud de los contenedores
  health_check {
    enabled             = true
    path                = "/actuator/health" # Ruta común en Spring Boot para Health Check
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
  tags = { Name = "spring-boot-target-group" }
}

# 3. Listener HTTPS (Puerto 443)
# Esta es la regla principal: el ALB escucha el tráfico 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = 443
  protocol          = "HTTPS"

  # Debes reemplazar el ARN siguiente con tu ARN de AWS Certificate Manager (ACM)
  # Si no tienes uno, crea uno gratuito en ACM.
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:282681674742:certificate/e124b862-15fe-4da0-938c-57ddbb5b68bd"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spring_boot_tg.arn
  }
}