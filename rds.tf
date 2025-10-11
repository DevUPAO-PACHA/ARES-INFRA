# --- rds.tf (RDS MySQL - Base de Datos) ---

# 1. Grupo de Subredes DB
# Necesario para que RDS se distribuya en las subredes privadas de datos (Alta Disponibilidad)
resource "aws_db_subnet_group" "private_db_group" {
  name       = "${var.project_name}-db-subnet-group"
  # Usa las subredes privadas de datos (db-az1, db-az2)
  subnet_ids = [aws_subnet.private_db[0].id, aws_subnet.private_db[1].id]
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. Instancia RDS (MySQL)
resource "aws_db_instance" "mysql_db" {
  # Alta Disponibilidad (Multi-AZ)
  multi_az             = true
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0" # Versión estándar
  instance_class       = "db.t3.small" # O db.t3.micro para desarrollo

  # Credenciales Maestras (Admin)
  username             = "admin"
  # La contraseña se obtiene del Secret Manager (¡Seguridad!)
  password             = random_password.db_master_password.result

  # Configuración de Red y Seguridad
  db_subnet_group_name = aws_db_subnet_group.private_db_group.name
  # Se le asigna el SG-RDS que solo permite tráfico del SG-Fargate
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Base de Datos y Nombre
  db_name              = "${var.project_name}_db"
  identifier           = "${var.project_name}-mysql-instance"

  # Retención y Backup
  skip_final_snapshot  = true # CÁMBIALO a 'false' en producción
  backup_retention_period = 7 # 7 días de backup

  # Parámetros de RDS
  parameter_group_name = "default.mysql8.0"
}