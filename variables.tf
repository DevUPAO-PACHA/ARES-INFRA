# Región de AWS para el despliegue
variable "aws_region" {
  description = "La región de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "us-east-2" # N. Virginia, común para CDN y alta disponibilidad
}

# Nombre del proyecto para etiquetar todos los recursos
variable "project_name" {
  description = "Prefijo usado para nombrar todos los recursos del proyecto de reservas."
  type        = string
  default     = "reserva-mesas"
}

# Bloque CIDR principal para la VPC
variable "vpc_cidr" {
  description = "El bloque CIDR principal para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}