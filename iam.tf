
# Define la entidad de confianza para los roles de ECS
data "aws_iam_policy_document" "ecs_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Define la entidad de confianza para CodePipeline
data "aws_iam_policy_document" "codepipeline_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# Rol de ejecucion

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

# Adjunta la política administrada de AWS (requerida para Fargate)
resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#Rol de Tareas de ECS

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

# Política para permitir a la aplicación (Spring Boot) leer los secretos y escribir en S3
resource "aws_iam_policy" "spring_boot_access_policy" {
  name = "${var.project_name}-springboot-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          # Permisos para leer Secrets Manager (donde estarán las credenciales DB)
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          # Permisos para escribir y leer en el Bucket S3 de Boletas/Assets (Integración #5)
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          # Se define el ARN del Secret (a codificar luego)
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*",
          # Se define el ARN del Bucket S3 (a codificar luego)
          "arn:aws:s3:::${var.project_name}-assets-bucket",
          "arn:aws:s3:::${var.project_name}-assets-bucket/*"
        ]
      },
    ]
  })
}

# Adjunta la política al Rol de Tareas
resource "aws_iam_role_policy_attachment" "ecs_task_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.spring_boot_access_policy.arn
}

# Rol para el PIPELINE

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_trust.json
}

# Permisos para que CodePipeline interactúe con los servicios
resource "aws_iam_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",                      # Leer/Escribir Artifacts en S3
          "ecr:GetAuthorizationToken", # Necesario para CodeBuild/Pipeline
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",              # Escribir la imagen Docker en ECR
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds",
          "ecs:DescribeServices",        # Desplegar a ECS
          "ecs:CreateTaskSet",
          "ecs:UpdateService",
          "ecs:DeleteTaskSet",
          "iam:PassRole",                # Para pasar los roles a Fargate
          "cloudwatch:*"                 # Integración #3 (Logs y Métricas)
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}