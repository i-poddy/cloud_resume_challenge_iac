# PROJECT SETTINGS

variable "project_name" {
  description = "The name of the project (used for tagging resources)"
  type        = string
  default     = "Cloud Resume Challenge"
}

variable "my_domain" {
  description = "The root domain you want to use to deploy the website" # You need to own that domain in your AWS account using route 53
  type        = string
}

# CI/CD SETTINGS

variable "github_username" {
  description = "Your Github Username"
  type        = string
}

variable "github_frontend_repo" {
  description = "Frontend repo name"
  type        = string
}

variable "github_backend_repo" {
  description = "Backend repo name"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

# VARIABLES USED IN CODE

locals {
  frontend_git_repository_url = "https://github.com/${var.github_username}/${var.github_frontend_repo}.git"
  backend_git_repository_url  = "https://github.com/${var.github_username}/${var.github_backend_repo}.git"
}
