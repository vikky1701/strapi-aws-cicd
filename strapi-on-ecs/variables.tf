variable "ecr_image_url" {
  description = "ECR image URL for Strapi application"
  type        = string
}

variable "db_name" {
  description = "Database name for PostgreSQL"
  type        = string
  default     = "mydb"
}

variable "db_user" {
  description = "Database username for PostgreSQL"
  type        = string
  default     = "myuser"
}

variable "db_password" {
  description = "Database password for PostgreSQL"
  type        = string
  default     = "mypassword"
  sensitive   = true
}