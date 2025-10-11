# --- Bloque C: Elastic IP (EIP) para el NAT Gateway ---
# Necesario para que el NAT Gateway tenga una IP pública estática
resource "aws_eip" "nat" {
  count = 2
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-eip-nat-az${count.index + 1}"
  }
}

# --- Bloque C: NAT Gateway en la Subred Pública ---
# Proporciona la salida a internet para los recursos en las subredes privadas (Fargate, RDS)
resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Colocado en la subred pública
  tags = {
    Name = "${var.project_name}-nat-az${count.index + 1}"
  }
}