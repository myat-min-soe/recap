# DevOps Tools Setup Guide

Clean and simple install commands for the DevOps Bootcamp Ubuntu workstation.

ဒီ guide က WSL Ubuntu or Ubuntu setup အတွက်ပါ။ Commands တွေကို script အနေနဲ့ run မလုပ်ဘဲ section တစ်ခုချင်းစီ copy/paste လုပ်ပြီး install လုပ်ပါ။

## Install Map

| Tool | Run in | Purpose |
| --- | --- | --- |
| Git | WSL Ubuntu / Ubuntu | Source code version control |
| AWS CLI v2 | WSL Ubuntu / Ubuntu | Manage AWS from terminal |
| Terraform | WSL Ubuntu / Ubuntu | Provision AWS infrastructure as code |
| Packer | WSL Ubuntu / Ubuntu | Build custom AMIs |
| Atmos | WSL Ubuntu / Ubuntu | Manage Terraform stacks and workflows |

## 1. Install Ubuntu Base Packages

Run in **WSL Ubuntu** or **Ubuntu terminal**.

```bash
sudo apt update
sudo apt install -y curl unzip wget gnupg software-properties-common apt-transport-https lsb-release apt-utils
```

## 2. Install Git

```bash
sudo apt update
sudo apt install -y git
git --version
```

## 3. Install AWS CLI v2

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
aws --version
```

For update later:

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
aws --version
```

## 4. Add HashiCorp APT Repository

Terraform and Packer both come from the HashiCorp APT repository. Add this repository once.

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
```

## 5. Install Terraform

```bash
sudo apt install -y terraform
terraform --version
```

## 6. Install Packer

```bash
sudo apt install -y packer
packer --version
```

## 7. Install Atmos

```bash
sudo apt-get update
sudo apt-get install -y apt-utils curl
curl -1sLf "https://dl.cloudsmith.io/public/cloudposse/packages/cfg/setup/bash.deb.sh" | sudo -E bash
sudo apt-get update
sudo apt-get install -y atmos
atmos version
```

## Final Check

```bash
git --version
aws --version
terraform --version
packer --version
atmos version
```

## Recap Docs

- [linux-recap.md](./linux-recap.md)
- [aws-recap.md](./aws-recap.md)
- [terraform-recap.md](./terraform-recap.md)

## Official References

- [AWS CLI v2 install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Git install for Linux](https://git-scm.com/install/linux)
- [Terraform install on Ubuntu/Debian](https://developer.hashicorp.com/terraform/cli/install/apt)
- [Packer install](https://developer.hashicorp.com/packer/install)
- [Atmos install](https://atmos.tools/install)
