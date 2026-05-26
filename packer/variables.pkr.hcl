variable "aws_region" {
  description = "AWS region where Packer builds the AMI."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name used by Packer."
  type        = string
  default     = "dev-mms"
}

variable "instance_type" {
  description = "Temporary EC2 instance type used by Packer."
  type        = string
  default     = "t3a.micro"
}

variable "ami_name_prefix" {
  description = "Prefix for the generated AMI name."
  type        = string
  default     = "devops-bootcamp-bagisto"
}

variable "ssh_username" {
  description = "SSH username for the source AMI."
  type        = string
  default     = "ubuntu"
}

variable "source_ami_owner" {
  description = "AWS account owner ID for the source AMI."
  type        = string
  default     = "099720109477"
}

variable "source_ami_name" {
  description = "Source AMI name filter."
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

variable "php_version" {
  description = "PHP version installed by the LEMP script."
  type        = string
  default     = "8.3"
}
