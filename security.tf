# --- 1. SG para el Application Load Balancer (SG-ALB) ---
# Permite el tráfico público de Internet (puerto 443)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Permite HTTPS (443) desde cualquier lugar."
  vpc_id      = aws_vpc.main.id

  # Regla de ENTRADA (Ingress): Tráfico HTTPS desde cualquier lugar (0.0.0.0/0)
  ingress {
    description = "Trafico HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de SALIDA (Egress): Permite salir a cualquier lugar (necesario para la salud del contenedor)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Cualquier protocolo
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-alb" }
}


# --- 2. SG para ECS Fargate (SG-Fargate / Spring Boot) ---
# Permite el tráfico SOLAMENTE desde el ALB (puerto 8080)
resource "aws_security_group" "fargate" {
  name        = "${var.project_name}-sg-fargate"
  description = "Permite acceso a la API (8080) solo desde el ALB."
  vpc_id      = aws_vpc.main.id

  # Regla de ENTRADA (Ingress): Tráfico 8080 desde el SG-ALB (Security Group Reference)
  ingress {
    description     = "Acceso desde ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # <- RESTRICTO AL ALB
  }

  # Regla de SALIDA (Egress): Permite salir a cualquier lugar (para NAT Gateway, S3, Secrets Manager)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-fargate" }
}


# --- 3. SG para RDS MySQL (SG-RDS) ---
# Permite el tráfico SOLAMENTE desde ECS Fargate (puerto 3306)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Permite MySQL (3306) solo desde los contenedores Fargate."
  vpc_id      = aws_vpc.main.id

  # Regla de ENTRADA (Ingress): Tráfico 3306 desde el SG-Fargate
  ingress {
    description     = "Acceso desde Fargate"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate.id] # <- RESTRICTO A FARGATE
  }

  # Regla de SALIDA (Egress): La DB NO necesita salida a internet (práctica recomendada)
  # Se permite salir SOLO a la VPC si fuera necesario, pero por defecto, solo a sí misma.
  # Para simplificar y mantener seguro, omitimos la regla egress (por defecto deniega todo, pero explícitamente:
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block] # Permite tráfico interno si es necesario, pero es opcional.
  }
  tags = { Name = "sg-rds" }
}