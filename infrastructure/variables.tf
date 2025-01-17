variable "cname" {
  description = "Company Name"
  type        = string
  default     = "qubika"
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
  default     = "ab925f1d-59ac-4773-9362-74eb88f803f1"
}