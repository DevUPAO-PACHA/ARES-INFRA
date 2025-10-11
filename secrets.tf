# --- secrets.tf (AWS Secrets Manager) ---

# Genera una contraseña segura y aleatoria para RDS
resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*" # Caracteres especiales permitidos en RDS
}

# 1. Crea el Secret en Secrets Manager
# Este secret almacenará la contraseña generada
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-db-secret-password"
  description             = "Contraseña maestra para la instancia RDS MySQL."
  # Se incluye el nombre del Secret en el ARN que referenciamos en ecs.tf
}

# 2. Almacena el valor de la contraseña en el Secret
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_master_password.result
}
