# --- ecr.tf (Repositorio de Imágenes Docker) ---

# Crea el ECR (Elastic Container Registry) para las imágenes de Spring Boot Fargate
resource "aws_ecr_repository" "spring_boot_repo" {
  name                 = "${var.project_name}-spring-boot-repo"
  # Permite que las etiquetas sean sobrescritas (necesario para el CI/CD)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    # Habilita el escaneo de seguridad de la imagen al subirla
    scan_on_push = true
  }

  tags = {
    Name = "spring-boot-ecr"
  }
}