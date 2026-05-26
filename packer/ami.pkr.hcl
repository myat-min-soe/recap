locals {
  build_timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  region        = var.aws_region
  profile       = var.aws_profile
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  ami_name      = "${var.ami_name_prefix}-${local.build_timestamp}"

  source_ami_filter {
    filters = {
      name                = var.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = [var.source_ami_owner]
    most_recent = true
  }

  tags = {
    Name        = "${var.ami_name_prefix}-${local.build_timestamp}"
    ImageRole   = "bagisto"
    Project     = "devops-bootcamp"
    Provisioner = "packer"
  }
}

build {
  name    = "bagisto"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "PHP_VERSION=${var.php_version}",
      "AWS_REGION=${var.aws_region}",
    ]
    script = "${path.root}/scripts/run.sh"
  }
}
