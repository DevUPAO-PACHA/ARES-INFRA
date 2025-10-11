# --- frontend.tf (Hosting Estático para Producción Segura) ---

# Variable del nombre del bucket (usaremos el nombre del proyecto)
variable "bucket_name_frontend" {
  description = "El nombre del bucket S3 para el frontend."
  type        = string
  default     = "reserva-mesas-frontend-testing"
}

# 1. Bucket S3 para alojar los archivos Angular
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "reserva-mesas-frontend-testing-bucket-for-frontend"
  tags = {
    Name = "frontend-hosting-bucket-test"
  }
}

# 3. Bloque de Datos (Necesario para la Política de CloudFront)
data "aws_iam_policy_document" "cf_s3_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.frontend_bucket.arn,
      "${aws_s3_bucket.frontend_bucket.arn}/*"
    ]

    # Condición crucial para OAC: asegura que solo la distribución específica pueda acceder.
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend_cdn.arn]
    }
  }
}

# --- OUTPUT (PARA OBTENER LA URL DE PRUEBA) ---
# Hemos cambiado el output para mostrar la URL de CloudFront, que es la correcta
output "frontend_url_test_s3_obsolete" {
  description = "La URL obsoleta del Website Hosting de S3."
  value       = "Verificar la URL de CloudFront para acceso."
}


output "cloudfront_domain_name" {
  description = "El nombre de dominio (URL) generado por CloudFront para acceder al Frontend."
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

resource "aws_s3_bucket_public_access_block" "frontend_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  # Deben ser false para permitir la lectura mediante la política CF/OAC
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}