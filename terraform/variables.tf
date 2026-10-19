variable "region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre corto del proyecto usado como prefijo de recursos"
  type        = string
  default     = "frontend"
}

variable "environment" {
  description = "Entorno de despliegue, por ejemplo dev, staging o prod"
  type        = string
  default     = "dev"
}

variable "container_image" {
  description = "URI completa de la imagen del frontend almacenada en un registry"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde residen los recursos"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para las tareas de ECS (Fargate)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs de las subredes públicas para el Application Load Balancer"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN del target group HTTP existente del frontend (target type IP)"
  type        = string
}

variable "desired_count" {
  description = "Cantidad inicial de tareas del servicio ECS"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Cantidad mínima de tareas para el escalado automático"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Cantidad máxima de tareas para el escalado automático"
  type        = number
  default     = 6
}