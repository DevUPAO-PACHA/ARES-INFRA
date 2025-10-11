
resource "aws_codestarconnections_connection" "github_backend_connection" {
  name          = "${var.project_name}-github-backend-connection"
  provider_type = "GitHub"
  tags          = { Name = "Backend-Source-Connection" }
}

resource "aws_codestarconnections_connection" "github_frontend_connection" {
  name          = "${var.project_name}-github-frontend-connection"
  provider_type = "GitHub"
  tags          = { Name = "Frontend-Source-Connection" }
}