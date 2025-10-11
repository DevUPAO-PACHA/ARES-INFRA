# 🧾 Proyecto: Infraestructura AWS – Sistema de Reservas de Mesas

## ⚙️ Descripción General
Este proyecto implementa la **infraestructura completa de un sistema de reservas de mesas** en AWS utilizando **Terraform**, bajo el enfoque de **Infraestructura como Código (IaC)**.  
El objetivo es desplegar un entorno seguro, escalable y automatizado para ejecutar una aplicación **Spring Boot (backend)** y **Angular (frontend)**.

---

## 🧩 Arquitectura General

La infraestructura se compone de los siguientes servicios principales en AWS:

- **VPC (Virtual Private Cloud)**: red aislada donde se despliegan todos los recursos.  
- **Subredes Públicas y Privadas**: separación de servicios internos (ECS, RDS) y externos (ALB, NAT).  
- **NAT Gateway**: permite a los recursos en subred privada acceder a Internet de forma segura.  
- **ECR (Elastic Container Registry)**: almacena las imágenes Docker del backend y frontend.  
- **ECS Fargate**: ejecuta los contenedores de la aplicación Spring Boot (backend).  
- **RDS MySQL**: base de datos relacional desplegada en subred privada.  
- **ALB (Application Load Balancer)**: distribuye el tráfico HTTP/HTTPS hacia los servicios ECS.  
- **S3 + CloudFront**: hospedan el frontend Angular y distribuyen el contenido de manera global.  
- **IAM Roles & Security Groups**: controlan permisos y comunicación segura entre servicios.  
- **CloudWatch**: recopila métricas y logs de los servicios desplegados.  

---

## 🗂️ Estructura del Proyecto

```bash
ARES-INFRA/
├── main.tf                # Configuración principal: VPC, Internet Gateway, Backend remoto
├── subnets.tf             # Definición de subredes públicas y privadas
├── nat.tf                 # Creación del NAT Gateway
├── routing.tf             # Tablas de ruteo para el tráfico interno/externo
├── security.tf            # Grupos de seguridad (ECS, RDS, ALB)
├── alb.tf                 # Configuración del Application Load Balancer
├── ecr.tf                 # Repositorio ECR para contenedores Docker
├── ecs.tf                 # Configuración de ECS Fargate (Backend)
├── rds.tf                 # Configuración de la base de datos MySQL
├── iam.tf                 # Roles y políticas de permisos IAM
├── frontend.tf            # Configuración del frontend (S3 + CloudFront)
├── cicd.tf                # Integración continua (CodePipeline y CodeBuild)
├── variables.tf           # Variables globales reutilizables
└── outputs.tf             # Parámetros y endpoints de salida
```

---

## 🔄 Flujo de la Infraestructura

1. **Cliente (navegador)** accede al sistema a través de Internet.  
2. **CloudFront** distribuye el contenido estático (Angular) desde **S3**.  
3. El **ALB (Application Load Balancer)** recibe las peticiones entrantes y las redirige al **ECS Fargate**, donde corre el backend Spring Boot.  
4. **ECS Fargate** se comunica con **RDS MySQL** para guardar y recuperar información (reservas, usuarios, mesas).  
5. **Logs y métricas** se gestionan mediante **CloudWatch**.  
6. **CodePipeline** y **CodeBuild** automatizan el flujo de CI/CD desde GitHub hacia ECS y S3.  

---

## 🧠 Relación entre los Archivos `.tf` y el Diagrama de AWS

| Archivo `.tf` | Componente AWS | Descripción |
|----------------|----------------|--------------|
| **main.tf** | VPC, IGW, NAT, Subnets | Crea toda la red base dentro de la VPC. |
| **security.tf** | Security Groups | Define las reglas de acceso entre ALB, ECS y RDS. |
| **ecs.tf** | ECS Fargate | Ejecuta el backend (Spring Boot) dentro de contenedores Docker. |
| **rds.tf** | RDS MySQL | Base de datos privada conectada solo al ECS. |
| **alb.tf** | Application Load Balancer | Distribuye el tráfico HTTP/HTTPS hacia ECS. |
| **frontend.tf** | S3 + CloudFront | Hospeda y distribuye el frontend Angular. |
| **ecr.tf** | Elastic Container Registry | Almacena las imágenes Docker del backend y frontend. |
| **cicd.tf** | CodePipeline + CodeBuild | Configura el flujo CI/CD para despliegues automáticos. |
| **iam.tf** | IAM Roles y Policies | Permite la comunicación segura entre servicios. |
| **outputs.tf** | Resultados | Muestra las URLs finales del ALB y CloudFront. |

---

## 🚀 Instrucciones de Despliegue

### ✅ Requisitos Previos

Antes de desplegar la infraestructura, asegúrate de contar con:

- Una **cuenta AWS** con permisos de administrador.  
- **AWS CLI** configurado (`aws configure`).  
- **Terraform v1.5+** instalado.  
- **Git** instalado para clonar el repositorio.

---

### 🪜 Pasos para Desplegar

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/<tu-usuario>/ARES-INFRA.git
   ```

2. **Acceder al directorio del proyecto:**
   ```bash
   cd ARES-INFRA
   ```

3. **Inicializar Terraform (descarga de módulos y backend):**
   ```bash
   terraform init
   ```

4. **Previsualizar los cambios que se aplicarán:**
   ```bash
   terraform plan
   ```

5. **Desplegar la infraestructura:**
   ```bash
   terraform apply
   ```

6. **(Opcional) Destruir la infraestructura:**
   ```bash
   terraform destroy
   ```

---

## 🧩 Flujo Completo del Sistema

```text
Cliente (Navegador)
   ↓
CloudFront (CDN)
   ↓
S3 (Frontend Angular)
   ↓
ALB (Load Balancer)
   ↓
ECS Fargate (Backend Spring Boot)
   ↓
RDS MySQL (Base de Datos)
```

Toda la infraestructura es gestionada por **Terraform** y los despliegues son automatizados mediante **CodePipeline**.

---
