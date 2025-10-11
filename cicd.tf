# --- cicd.tf (AWS CodePipeline y CodeBuild) ---

# 0. Dependencia de datos (Declarada SOLO AQUÍ para evitar duplicados)
data "aws_caller_identity" "current" {}

# 1. Bucket de Artifacts (Necesario para CodePipeline)
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts"
  tags = { Name = "codepipeline-artifacts" }
}

# =========================================================================
# === PIPELINE DEL BACK-END (SPRING BOOT A ECS) ===========================
# =========================================================================

# 2. CodeBuild para el Back-end (Docker Build & Push)
resource "aws_codebuild_project" "backend_build" {
  name           = "${var.project_name}-backend-build"
  description    = "Construye la imagen Docker de Spring Boot y la sube a ECR."
  service_role   = aws_iam_role.codepipeline_role.arn
  build_timeout  = "5"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type          = "LINUX_CONTAINER"
    compute_type  = "BUILD_GENERAL1_SMALL"
    image         = "aws/codebuild/standard:5.0"
    privileged_mode = true

    # SINTAXIS CORREGIDA: Bloques environment_variables anidados y separados por líneas
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_URL"
      value = aws_ecr_repository.spring_boot_repo.repository_url
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source { type = "CODEPIPELINE" }
}

# 3. CodePipeline para el Back-end
resource "aws_codepipeline" "backend_pipeline" {
  name     = "${var.project_name}-backend-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  # SINTAXIS CORREGIDA: Bloque artifact_store en líneas separadas
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # --- ETAPA 1: FUENTE (GitHub) ---
  stage {
    name = "Source"
    action {
      name             = "Source-Backend"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["BackendSourceArtifact"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_backend_connection.arn # <--- ARTEFACTO DE CONEXIÓN
        FullRepositoryId = "angeloncoy/ARES-BACK" # <--- Formato: Usuario/Repo
        BranchName       = "main"
        # OAuthToken, Owner, y Repo YA NO son necesarios
      }
    }
  }

  # --- ETAPA 2: BUILD (CodeBuild) ---
  stage {
    name = "Build"
    action {
      name             = "Docker-Build-Push"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["BackendSourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration = { ProjectName = aws_codebuild_project.backend_build.name }
    }
  }

  # --- ETAPA 3: DESPLIEGUE (ECS Fargate) ---
  stage {
    name = "Deploy"
    action {
      name             = "Deploy-to-ECS"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["BuildArtifact"]
      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.spring_boot_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

# =========================================================================
# === PIPELINE DEL FRONT-END (ANGULAR A S3) ===============================
# =========================================================================

# 4. CodeBuild para el Front-End (Angular Build)
resource "aws_codebuild_project" "frontend_build" {
  name           = "${var.project_name}-frontend-build"
  description    = "Construye la aplicación Angular para hosting estático."
  service_role   = aws_iam_role.codepipeline_role.arn
  build_timeout  = "5"

  artifacts { type = "CODEPIPELINE" }
  environment {
    type          = "LINUX_CONTAINER"
    compute_type  = "BUILD_GENERAL1_SMALL"
    image         = "aws/codebuild/standard:5.0"
  }
  source { type = "CODEPIPELINE" }
}

# 5. CodePipeline para el Front-End
resource "aws_codepipeline" "frontend_pipeline" {
  name     = "${var.project_name}-frontend-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # --- ETAPA 1: FUENTE (GitHub FRONTEND - CORREGIDO) ---
  stage {
    name = "Source"
    action {
      name             = "Source-Angular"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["FrontendSourceArtifact"]

      # CORRECCIÓN 2: Se eliminan los campos obsoletos (Owner, Repo, OAuthToken)
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_frontend_connection.arn # <--- Conexión segura
        FullRepositoryId = "angeloncoy/ARES-LANDING"
        BranchName       = "main"
        # OAuthToken, Owner, Repo y PollForSourceChanges eliminados.
      }
    }
  }

  # --- ETAPA 2: BUILD (CodeBuild) ---
  stage {
    name = "Build"
    action {
      name             = "Angular-Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["FrontendSourceArtifact"]
      output_artifacts = ["FrontendBuildArtifact"]
      configuration = { ProjectName = aws_codebuild_project.frontend_build.name }
    }
  }

  # --- ETAPA 3: DESPLIEGUE (S3) ---
  stage {
    name = "Deploy"
    action {
      name             = "Deploy-to-S3"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      input_artifacts  = ["FrontendBuildArtifact"]
      configuration = {
        BucketName = aws_s3_bucket.frontend_bucket.bucket
        Extract = "true"
      }
    }
  }
}