variable "ami_id" {
  description = "AMI for private EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Ubuntu 22.04 eu-north-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}
