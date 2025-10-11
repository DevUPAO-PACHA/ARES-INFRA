# 1. Definir el Origen (el bucket S3)
/*resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "reserva-mesas-frontend-oac"
  description                       = "OAC para S3 Frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}*/

# 2. Crear la Distribución de CloudFront (CDN)
resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend_bucket.id}"

  }

  enabled             = true
  is_ipv6_enabled     = true
  # CORRECTO: Va aquí, en el nivel superior del recurso
  default_root_object = "index.html" # Archivo de entrada de Angular


  # --- Bloque 'restrictions' AÑADIDO (Ahora en la ubicación correcta) ---
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  # -------------------------------------


  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.frontend_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

  }

  # Configuración mínima de certificado (usa el certificado predeterminado de CloudFront)
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}