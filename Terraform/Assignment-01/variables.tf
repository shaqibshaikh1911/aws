variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "ap-south-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # ← Replace with your key
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # ← Replace with your secret
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair registered in AWS"
  default     = "learn"
}

variable "flask_port" {
  description = "Port for Flask backend"
  default     = 5000
}

variable "express_port" {
  description = "Port for Express frontend"
  default     = 3000
}