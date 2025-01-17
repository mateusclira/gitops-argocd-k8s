variable "cname" {
  description = "Company Name"
  type        = string
  default     = "my-company"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "eastus"
}

# This is only for the Azure Pipeline
# variable "ENV_ID" {}
# variable "SUBSCRIPTION_ID" {}

# Azure DevOps is out of scope for the blog post, so I'm creating hard-coded values
variable "ENV_ID" {
  description = "Environment ID"
  type        = string
  default     = "dev"
}

variable "SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}