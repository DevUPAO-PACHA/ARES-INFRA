# --- frontend.tf (Hosting Estático SOLO para Fines practicos) ---

# Variable del nombre del bucket (usaremos el nombre del proyecto)
variable "bucket_name_frontend" {
  description = "El nombre del bucket S3 para el frontend."
  type        = string
  default     = "reserva-mesas-frontend-testing"
}

# 1. Bucket S3 para alojar los archivos Angular
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.bucket_name_frontend
  tags = {
    Name = "frontend-hosting-bucket-test"
  }
}

# 2. Configuración del Bucket para Web Hosting Estático
# Esto habilita el endpoint URL para el sitio web estático.
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # Importante para las rutas SPA de Angular
  }
}

# 3. Política de Acceso PÚBLICO (¡Solo para Testing/Demo!)
# Esto es necesario para que el S3 sirva el contenido a Internet directamente.
resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "public-read"
}

data "aws_iam_policy_document" "s3_public_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.frontend_bucket.arn,
      "${aws_s3_bucket.frontend_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.s3_public_policy.json
}

# --- OUTPUT (PARA OBTENER LA URL DE PRUEBA) ---
output "frontend_url_test" {
  description = "La URL pública para acceder al frontend de prueba."
  value       = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
}



# --- frontend.tf (Front-End Hosting Estático con dominio) ---
/*
# Variable para el nombre de tu dominio
variable "domain_name" {
  description = "El dominio principal www.pacha-restaurante.com"
  type        = string
  # ¡IMPORTANTE! REEMPLAZA con tu dominio real
  default     = "www.pacha-restaurante.com"
}

# 1. Obtener la Zona Hospedada (Route 53 Hosted Zone)
data "aws_route53_zone" "main" {
  name = "${var.domain_name}."
}

# 2. Bucket S3 para alojar los archivos Angular
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.domain_name
  tags = {
    Name = "frontend-hosting-bucket"
  }
}

# Configuración del Bucket para Web Hosting Estático (Necesario para el CI/CD y acceso)
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # Para manejo de rutas SPA (ej: /reservas)
  }
}

# 3. CloudFront Origin Access Identity (OAI)
# El OAI es una identidad virtual que CloudFront usará para leer el bucket S3 (práctica de seguridad)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI para ${var.domain_name} CloudFront distribution"
}

# 4. Política de Bucket S3 (Permite acceso SOLO desde CloudFront OAI)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.frontend_bucket.arn,
      "${aws_s3_bucket.frontend_bucket.arn}/*",
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy"
    ]
    resources = [aws_s3_bucket.frontend_bucket.arn]
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# 5. Distribución CloudFront (CDN)
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend_bucket.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_id
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN para ${var.domain_name} Front-End"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    # ¡IMPORTANTE! El certificado debe estar en us-east-1 (N. Virginia) para CloudFront.
    acm_certificate_arn = "arn:aws:acm:us-east-1:282681674742:certificate/e124b862-15fe-4da0-938c-57ddbb5b68bd"
    ssl_support_method  = "sni-only"
  }
}

# 6. Registro Route 53 (Conexión del Dominio)
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}*/