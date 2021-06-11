#this module set our clusters parameters as variables
variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "cluster_name" {
  default = "SelaTask-eks"
}
