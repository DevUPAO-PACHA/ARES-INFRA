# --- Bloque D: Tabla de Ruteo PÚBLICA (dirige el tráfico externo a la IGW) ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# Asociación de las Subredes Públicas a la Tabla de Ruteo PÚBLICA
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Bloque D: Tablas de Ruteo PRIVADAS (dirige la salida al NAT Gateway) ---
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id
  route {
    # Referencia al NAT Gateway creado en nat.tf
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = { Name = "${var.project_name}-private-rt-az${count.index + 1}" }
}

# Asociación: App Subnets a la Tabla de Ruteo PRIVADA
resource "aws_route_table_association" "app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Asociación: DB Subnets a la Tabla de Ruteo PRIVADA
resource "aws_route_table_association" "db" {
  count          = 2
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}