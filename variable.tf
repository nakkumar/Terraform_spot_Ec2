variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.0.0/16"
}

variable "pub_sub_cidr1" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.1.0/24"
}

variable "pub_sub_cidr2" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.2.0/24"
}

variable "pri_sub_cidr1" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.3.0/24"
}

variable "pri_sub_cidr2" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.4.0/24"
}

