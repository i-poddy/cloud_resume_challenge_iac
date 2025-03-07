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

variable "frontend_git_repository_url" {
  description = "The URL of the Git repository containing the frontend code"
  type        = string
}

variable "backend_git_repository_url" {
  description = "The URL of the Git repository containing the backend code" # Maybe I will collapse this in a single repo with IaC 
  type        = string
}