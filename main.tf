# CONFIGURACIÓN DE TERRAFORM Y BACKEND

terraform {
  # Definición del backend para almacenar el estado de forma remota
  # (¡CRÍTICO en IaC! Debe apuntar a un Bucket S3 real)
  # Este bloque no se ejecuta, solo configura Terraform.

  /*
  backend "s3" {
    bucket         = "tfstate-reserva-mesas-12345" # Reemplazar con el nombre real del bucket
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-lock-table" # Para prevenir modificaciones simultáneas (bloqueo)
  }
  */

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

# CONFIGURACIÓN DEL PROVEEDOR AWS

provider "aws" {
  # Utiliza la variable definida en variables.tf (default: us-east-1)
  region = var.aws_region
}

# FUENTES DE DATOS (DATA SOURCES)

# Obtiene dinámicamente las Availability Zones (AZs) disponibles para Alta Disponibilidad
data "aws_availability_zones" "available" {
  state = "available"
}


# RECURSOS PRINCIPALES DE LA VPC (Bloque A)

# 1. Crea la VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr # Utiliza el CIDR definido en variables.tf (default: 10.0.0.0/16)
  enable_dns_support   = true         # Habilita resolución de DNS dentro de la VPC
  enable_dns_hostnames = true         # Permite que los hostnames de AWS se resuelvan
  tags = {
    Name = "${var.project_name}-vpc"
    # Etiqueta de entorno
    Environment = "Production"
  }
}

# 2. Crea la Internet Gateway (IGW) - Permite la comunicación pública IN/OUT
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}
