# Terraform Recap

## Terraform ဆိုတာဘာလဲ

Terraform က Infrastructure as Code (IaC) tool တစ်ခုပါ။ Cloud console ထဲ manual click လုပ်ပြီး resources တွေ create မယ့်အစား `.tf` files ထဲမှာ infrastructure ကို code အနေနဲ့ရေးပြီး Terraform က create/update/delete လုပ်ပေးပါတယ်။

HashiCorp ကနေ develop လုပ်ထားပြီး AWS, GCP, Azure, Kubernetes အပါအဝင် provider 1,000+ ကို support ပါတယ်။

Core idea — **Desired State**:

```text
ကိုယ်လိုချင်တဲ့ infrastructure state ကို code ထဲရေးထားတယ်
Terraform က real AWS state နဲ့နှိုင်းယှဉ်ပြီး diff ကိုတွက်ပေးတယ်
Apply လုပ်ရင် diff အတိုင်း AWS မှာပြောင်းပေးတယ်
```

---

## Terraform ဘယ်လိုအလုပ်လုပ်လဲ

Terraform run တဲ့အခါ ဒီ steps အတိုင်းသွားပါတယ်။

```text
1. .tf files တွေကိုဖတ်တယ်
2. Provider plugin (AWS) ကိုသုံးတယ်
3. Variables တွေကို resolve လုပ်တယ်
4. Resource dependency graph တည်ဆောက်တယ်
5. State file ထဲက previous infrastructure state ကိုဖတ်တယ်
6. AWS API ကိုခေါ်ပြီး current real state ကိုစစ်တယ်
7. Desired state vs current state compare လုပ်တယ်
8. Plan ထုတ်တယ်
9. Apply လုပ်ရင် AWS API ကိုခေါ်ပြီး create/update/delete လုပ်တယ်
10. State file ကို update လုပ်တယ်
```

Terraform က shell script မဟုတ်ပါ။ Line by line run တာမဟုတ်ဘဲ dependency graph အတိုင်း resource creation order ကိုဆုံးဖြတ်ပါတယ်။

---

## Folder Structure

```text
terraform/
  environments/
    dev/
      main.tf          # root module - module calls
      variables.tf     # input variable declarations
      outputs.tf       # output value declarations
      providers.tf     # AWS provider config
      backend.tf       # remote state config
      versions.tf      # required provider versions
    staging/
    prod/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
    ec2/
    rds/
    alb/
    iam/
```

`environments/` ထဲတစ်ခုချင်းစီက environment အတွက် root module ပါ။ `modules/` ထဲကတွေက reusable child modules ပါ။

---

## Root Module vs Child Module

**Root module** ဆိုတာ `terraform init / plan / apply` run လုပ်တဲ့ main directory ပါ။

**Child module** ဆိုတာ root module ကနေ call လုပ်တဲ့ reusable Terraform folder ပါ။

Root module မှာ child module ကိုခေါ်တဲ့ syntax:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  cidr_block   = var.vpc_cidr
}
```

Child module output ကို root module ကနေ reference လုပ်ခြင်း:

```hcl
module "ec2" {
  source = "../../modules/ec2"

  subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id = module.alb.ec2_security_group_id
  iam_instance_profile = module.iam.instance_profile_name
}
```

---

## Resource Block

Resource block က real infrastructure object တစ်ခုကို represent လုပ်ပါတယ်။

```hcl
resource "RESOURCE_TYPE" "LOCAL_NAME" {
  argument = value
}
```

ဥပမာ:

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

- `aws_instance` — resource type
- `app` — Terraform local name (code ထဲမှာ reference လုပ်ဖို့ပဲသုံးတယ်)
- `ami`, `instance_type`, `subnet_id` — arguments (ကိုယ်ပေးတဲ့ input)
- `tags` — AWS resource tags

**Resource address** format:

```text
# root module
aws_instance.app

# child module
module.ec2.aws_instance.app

# nested module
module.parent.module.child.aws_instance.app
```

---

## Arguments vs Attributes

**Arguments** — resource create တဲ့အခါ ကိုယ်ပေးတဲ့ input values

```hcl
resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"   # argument
  instance_type = "t3.micro"                # argument
}
```

**Attributes** — Terraform apply ပြီးမှ AWS ကပြန်ပေးတဲ့ values

```hcl
aws_instance.app.id          # attribute
aws_instance.app.private_ip  # attribute
aws_instance.app.arn         # attribute
```

Attributes တွေကို တခြား resource မှာ reference လုပ်နိုင်ပါတယ်:

```hcl
resource "aws_lb_target_group_attachment" "app" {
  target_id = aws_instance.app.id   # EC2 instance ID ကို reference လုပ်တယ်
  port      = 80
}
```

---

## Data Source

Data source က existing AWS resource information ကို lookup လုပ်ပါတယ်။ Resource အသစ်မဖန်တီးပါ။

```hcl
# existing AMI lookup
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-24.04-amd64-server-*"]
  }
}

# existing VPC lookup
data "aws_vpc" "default" {
  default = true
}

# existing secret lookup
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db"
}
```

Reference:

```hcl
ami = data.aws_ami.ubuntu.id
vpc_id = data.aws_vpc.default.id
```

Data source ကို ဘယ်အခါသုံးသင့်လဲ:

- Packer ကနေ build ထားတဲ့ custom AMI ကို lookup လုပ်တဲ့အခါ
- Existing (Terraform manage မလုပ်တဲ့) resource ကိုချိတ်တဲ့အခါ
- Secrets Manager မှာ store ထားတဲ့ secret ဖတ်တဲ့အခါ
- Current region, account ID lookup လုပ်တဲ့အခါ

---

## Implicit Dependency

Terraform က attribute reference ကိုကြည့်ပြီး creation order ကိုအလိုအလျောက်သိပါတယ်။

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id   # implicit dependency
  cidr_block = "10.0.1.0/24"
}
```

`aws_subnet.public` က `aws_vpc.main.id` ကို reference လုပ်တဲ့အတွက် Terraform က VPC ကိုအရင် create ပြီးမှ subnet ကို create မယ်လို့သိပါတယ်။

---

## Explicit Dependency

`depends_on` နဲ့ dependency ကိုကိုယ်တိုင်သတ်မှတ်ပါတယ်။

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_db_instance.main
  ]
}
```

`depends_on` ကိုသုံးသင့်တဲ့ scenario:

- IAM policy attachment ပြီးမှ EC2 instance start ဖြစ်စေချင်တဲ့အခါ
- Resource တစ်ခုက တခြားတစ်ခုကို attribute reference မလုပ်ပေမယ့် real-world မှာ order လိုတဲ့အခါ
- AWS eventually consistent behavior ကြောင့် explicit order ပြတ်သားစေချင်တဲ့အခါ

`depends_on` ကို overuse မလုပ်ပါနဲ့။ Reference နဲ့ဖြေရှင်းလို့ရရင် reference ကိုသုံးပါ။

---

## Variables

Variable declaration:

```hcl
variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "allowed_cidrs" {
  description = "List of CIDRs allowed to access the application."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
```

Usage:

```hcl
instance_type = var.instance_type
environment   = var.environment
```

Variable value precedence (low to high):

```text
1. default value
2. terraform.tfvars
3. *.auto.tfvars
4. -var flag   (terraform plan -var="env=prod")
5. -var-file   (terraform plan -var-file="prod.tfvars")
6. TF_VAR_name environment variable
```

Variable types:

```hcl
type = string
type = number
type = bool
type = list(string)
type = map(string)
type = set(string)
type = object({ name = string, age = number })
type = tuple([string, number, bool])
```

---

## Outputs

```hcl
output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "db_endpoint" {
  description = "RDS endpoint."
  value       = aws_db_instance.main.endpoint
  sensitive   = true   # plan/apply output မှာ မပြဘဲ state မှာသိမ်းတယ်
}
```

Child module output ကို root module ကနေ:

```hcl
module.vpc.vpc_id
module.vpc.private_subnet_ids
module.rds.db_endpoint
```

---

## Locals

Locals ဆိုတာ reusable expressions တွေကို module ထဲမှာ define လုပ်ထားတဲ့ named values ပါ။ Variables နဲ့မတူဘဲ external ကနေ value ပေးလို့မရပါ။

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}
```

---

## Providers

Provider က Terraform နဲ့ cloud/service API ကြား connector ပါ။

```hcl
# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

Multiple provider configurations (different regions):

```hcl
provider "aws" {
  region = "ap-southeast-1"
  alias  = "singapore"
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# CloudFront certificate must be in us-east-1
resource "aws_acm_certificate" "cloudfront" {
  provider    = aws.virginia
  domain_name = var.domain_name
}
```

---

## Backend and State

Terraform state က Terraform က manage လုပ်နေတဲ့ real resources information ကိုသိမ်းထားတဲ့ file ပါ။ Resource IDs, attributes, dependencies တွေပါနိုင်ပြီး sensitive values လည်းပါနိုင်ပါတယ်။

**Local backend** (single developer, testing):

```hcl
# default, no config needed
# state: terraform.tfstate in current directory
```

**S3 remote backend** (team, production):

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"
    key     = "environments/prod/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true

    # S3 native locking (Terraform 1.10+, no DynamoDB needed)
    use_lockfile = true
  }
}
```

Remote backend ကောင်းတဲ့အကြောင်းရင်းတွေ:

- Team members အားလုံး same state ကိုသုံးနိုင်တယ်
- Local machine ပျက်လည်း state မပျောက်ဘူး
- State locking — တစ်ချိန်တည်း apply နှစ်ခုမဖြစ်အောင်ကာကွယ်ပေးတယ်
- Encryption — state ထဲပါတဲ့ sensitive values ကိုကာကွယ်တယ်

State file safety rules:

- `.tfstate` files ကို Git ထဲ commit မလုပ်ပါ
- State bucket ကို public မဖွင့်ပါ
- Encryption enable ထားပါ
- Access ကို လိုအပ်တဲ့ role/user တွေပဲပေးပါ

---

## Count and For_each

**count** — simple number-based repetition:

```hcl
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-${count.index + 1}"
  }
}

# reference
aws_subnet.private[0].id
aws_subnet.private[*].id  # all IDs as list
```

**for_each** — map/set-based iteration (preferred for named resources):

```hcl
variable "buckets" {
  default = {
    logs    = "my-app-logs"
    assets  = "my-app-assets"
    backups = "my-app-backups"
  }
}

resource "aws_s3_bucket" "app" {
  for_each = var.buckets
  bucket   = each.value

  tags = {
    Name    = each.key
    Purpose = each.key
  }
}

# reference
aws_s3_bucket.app["logs"].id
aws_s3_bucket.app["assets"].bucket
```

count vs for_each ရွေးတဲ့ rule:

```text
count   -> identical resources, number-based (3 EC2 instances)
for_each -> named resources, map-based (different S3 buckets)
```

List order ပြောင်းရင် count resource addresses တွေပြောင်းသွားပြီး unintended replacement ဖြစ်နိုင်ပါတယ်။ Stable named items ဆိုရင် for_each ပိုကောင်းတယ်။

---

## Dynamic Blocks

Repeated nested blocks တွေကို loop လုပ်ချင်ရင် dynamic block သုံးပါတယ်။

```hcl
variable "ingress_rules" {
  default = [
    { port = 80,  protocol = "tcp", cidr = "0.0.0.0/0" },
    { port = 443, protocol = "tcp", cidr = "0.0.0.0/0" },
  ]
}

resource "aws_security_group" "web" {
  name   = "${local.name_prefix}-web-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Lifecycle

`lifecycle` block က Terraform resource behavior ကိုထိန်းချုပ်ပါတယ်။

```hcl
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  lifecycle {
    prevent_destroy       = true          # accidental destroy ကာကွယ်တယ်
    create_before_destroy = true          # replacement မှာ အသစ်ကိုအရင်ဆောက်တယ်
    ignore_changes        = [password]    # external changes ကို ignore လုပ်တယ်
  }
}
```

Real-world patterns:

```hcl
# Auto Scaling Group - instance refresh ဖြစ်ရင် downtime မဖြစ်အောင်
resource "aws_autoscaling_group" "app" {
  lifecycle {
    create_before_destroy = true
  }
}

# RDS - production DB accidental delete ကာကွယ်ရန်
resource "aws_db_instance" "prod" {
  lifecycle {
    prevent_destroy = true
  }
}

# ACM certificate - external tool ကနေ renew လုပ်တဲ့အတွက် Terraform ignore
resource "aws_acm_certificate" "main" {
  lifecycle {
    create_before_destroy = true
  }
}
```

`ignore_changes` ကိုသတိထားပါ:

```hcl
# ECS task definition - external deploy tool ကနေ image ပြောင်းတာကို Terraform ဘာမှမလုပ်အောင်
resource "aws_ecs_task_definition" "app" {
  lifecycle {
    ignore_changes = [container_definitions]
  }
}
```

`ignore_changes` ကိုအလွယ်မသုံးပါနဲ့ — drift ကိုဖုံးကွယ်သွားနိုင်ပါတယ်။

---

## Terraform Plan Output ဖတ်တတ်ဖို့

Plan symbols:

```text
+   create       (new resource)
~   update       (in-place change)
-   destroy      (delete resource)
-/+ destroy and recreate (replacement)
<=  read         (data source)
```

Plan output ဥပမာ:

```text
Terraform will perform the following actions:

  # module.ec2.aws_instance.app will be created
  + resource "aws_instance" "app" {
      + ami                    = "ami-0abcdef1234567890"
      + instance_type          = "t3.micro"
      + id                     = (known after apply)
      + private_ip             = (known after apply)
    }

  # module.rds.aws_db_instance.main will be updated in-place
  ~ resource "aws_db_instance" "main" {
        id                     = "db-ABCDEFGHIJ"
      ~ backup_retention_period = 7 -> 14
    }

  # module.ec2.aws_security_group.app will be replaced
  -/+ resource "aws_security_group" "app" {
      - name = "old-name" -> null
      + name = "new-name"
    }

Plan: 1 to add, 1 to change, 0 to destroy.
```

Plan ဖတ်တဲ့အခါ စစ်ရမယ့်အချက်တွေ:

- **Destroy** ဖြစ်မယ့် resource ရှိလား — production DB, S3 bucket တွေ destroy ဖြစ်မဖြစ်
- **Replace** ဖြစ်မယ့် resource ရှိလား — EC2/RDS replace ဖြစ်ရင် downtime ဖြစ်နိုင်တယ်
- **Security group** rules မှန်လား — public access မလိုဘဲ ဖွင့်မိမနေဖြစ်
- **RDS publicly_accessible** false ဖြစ်လား
- Resource count မှန်လား — မလိုဘဲ resource extra ဖြစ်နေမနေ

---

## Drift

Drift ဆိုတာ Terraform code/state နဲ့ real AWS resource မကိုက်တော့တာပါ။

```text
Example:
Terraform code မှာ security group port 80 ပဲဖွင့်ထားတယ်
တစ်ယောက်က AWS console ထဲကနေ port 22 ကို manual ထပ်ဖွင့်တယ်
Real AWS state က Terraform code နဲ့မကိုက်တော့ဘူး  -->  drift
```

Drift စစ်နည်း:

```bash
terraform plan   # code နဲ့ real state diff ကိုပြပေးတယ်
terraform refresh  # state ကို real AWS state နဲ့ sync လုပ်တယ်
```

Drift ကာကွယ်နည်း:

- Infrastructure ကို console ကနေ manual မပြင်ပါ
- Change ကို code ထဲမှာပြောင်းပြီး Terraform ကနေသွားပါ
- Regular `terraform plan` run ပြီး unexpected changes စစ်ပါ

---

## Import

ရှိပြီးသား AWS resource ကို Terraform management ထဲသွင်းချင်ရင် `terraform import` သုံးနိုင်ပါတယ်။

Terraform 1.5+ မှာ import block သုံးလို့ရပါတယ်:

```hcl
# import.tf
import {
  to = aws_vpc.main
  id = "vpc-0abc123def456"
}

import {
  to = aws_s3_bucket.logs
  id = "my-existing-logs-bucket"
}
```

CLI import:

```bash
terraform import aws_vpc.main vpc-0abc123def456
terraform import module.vpc.aws_vpc.main vpc-0abc123def456
```

Import ပြီးနောက် workflow:

```bash
# 1. import လုပ်တယ်
terraform import aws_vpc.main vpc-0abc123def456

# 2. state ထဲမှာ resource ရောက်ပြီ - .tf code ရေးရပါမယ်
terraform state show aws_vpc.main   # existing config ကိုကြည့်ပြီး .tf ရေးပါ

# 3. plan စစ်ပါ - no changes ဖြစ်ရမယ်
terraform plan
```

Import က resource ကို create မလုပ်ပါ — existing resource ကို Terraform state ထဲချိတ်ပေးတာပါ။

---

## Workspaces

Workspace ဆိုတာ same Terraform config ကို isolated state နဲ့ run ဖြစ်အောင်လုပ်တာပါ။

```bash
terraform workspace list
terraform workspace new staging
terraform workspace select prod
terraform workspace show
```

Workspace ကို code ထဲမှာ reference:

```hcl
locals {
  env = terraform.workspace   # "default", "staging", "prod"
}

resource "aws_instance" "app" {
  instance_type = local.env == "prod" ? "t3.large" : "t3.micro"
}
```

Real-world note:

Workspace approach ကို simple projects မှာ convenient ဖြစ်ပေမယ့် large/complex infrastructure မှာ separate directories (environments/dev, environments/prod) နဲ့ separate state ကိုသုံးတာ manage ပိုလွယ်တာများပါတယ်။

---

## Module Versioning

Public Terraform Registry modules တွေကို version pin လုပ်ပြီးသုံးနိုင်ပါတယ်:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name_prefix
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
}
```

Version constraints:

```text
"5.0.0"    -> exact version
"~> 5.0"   -> 5.x.x (patch updates allowed)
"~> 5.0.0" -> 5.0.x only (micro updates allowed)
">= 5.0"   -> 5.0 or higher
```

---

## Real-world CI/CD Pattern

Production Terraform workflow:

```text
Developer makes .tf changes
  -> terraform fmt
  -> terraform validate
  -> git push -> Pull Request
  -> CI: terraform plan (auto)
  -> Team reviews plan output
  -> PR approved + merged
  -> CI: terraform apply (manual trigger or auto on merge to main)
  -> Monitor CloudWatch / AWS Console
```

GitHub Actions example:

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.10.0"

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/prod

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: terraform/environments/prod
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Upload Plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: terraform/environments/prod/tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    environment: production   # manual approval gate
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: terraform/environments/prod

      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: terraform/environments/prod
```

Best practices:

- Local machine ကနေ production apply တိုက်ရိုက်မလုပ်ပါ
- CI runner ကနေ apply လုပ်ပြီး approval gate ထားပါ
- Plan artifact ကို apply stage မှာသုံးပါ (plan again မလုပ်ပါနဲ့)
- AWS credentials ကို OIDC နဲ့ short-lived token သုံးတာ access key ထက်ပိုကောင်းတယ်

---

## Sensitive Values Handling

```hcl
variable "db_password" {
  type      = string
  sensitive = true    # plan/apply output မှာ *** ပြတယ်
}

output "db_connection_string" {
  value     = "postgresql://user:${aws_db_instance.main.password}@${aws_db_instance.main.endpoint}"
  sensitive = true
}
```

Secrets management patterns:

```hcl
# Secrets Manager မှာ secret ကို create ပြီး value ကို separate tool နဲ့ set လုပ်တာ
resource "aws_secretsmanager_secret" "db" {
  name = "${local.name_prefix}/database"
}

# RDS managed password (recommended)
resource "aws_db_instance" "main" {
  manage_master_user_password = true   # AWS က auto-rotate လုပ်ပေးတယ်
}
```

---

## Terraform Commands

### Initial Setup

```bash
# provider plugins download, backend initialize
terraform init

# backend မသုံးဘဲ init (validation only)
terraform init -backend=false

# provider version upgrade
terraform init -upgrade
```

### Format and Validate

```bash
# code formatting (auto fix)
terraform fmt

# recursive formatting (all subdirectories)
terraform fmt -recursive

# check formatting without fixing (CI မှာ)
terraform fmt -check -recursive

# configuration validation
terraform validate
```

### Plan

```bash
# standard plan
terraform plan

# plan ကို file ထဲ save ပြီး apply မှာသုံးဖို့
terraform plan -out=tfplan

# specific variable override
terraform plan -var="environment=staging"

# var file သုံးတဲ့ plan
terraform plan -var-file="staging.tfvars"

# specific resource တစ်ခုပဲ plan
terraform plan -target=module.ec2.aws_instance.app

# destroy plan ကြည့်ချင်ရင်
terraform plan -destroy
```

### Apply

```bash
# plan ပြပြီး confirmation မေးတယ်
terraform apply

# auto-approve (CI မှာသုံး)
terraform apply -auto-approve

# saved plan file ကို apply
terraform apply tfplan

# specific resource ပဲ apply
terraform apply -target=module.ec2.aws_instance.app
```

### Destroy

```bash
# plan ပြပြီး destroy confirmation မေးတယ်
terraform destroy

# auto-approve
terraform destroy -auto-approve

# specific resource ပဲ destroy
terraform destroy -target=module.rds.aws_db_instance.main
```

### State Management

```bash
# state ထဲက resource list
terraform state list

# specific resource detail ကြည့်ရန်
terraform state show module.ec2.aws_instance.app

# resource ကို state ထဲကဖယ်ရှားရန် (AWS မဖျက်ပါ)
terraform state rm module.ec2.aws_instance.app

# resource ကို state ထဲ import ရန်
terraform import module.ec2.aws_instance.app i-0abc123def456

# resource ကို state ထဲမှာ rename ရန်
terraform state mv module.old.aws_instance.app module.new.aws_instance.app

# real AWS state နဲ့ state ကို sync
terraform refresh
```

### Output

```bash
# all outputs ကြည့်ရန်
terraform output

# specific output
terraform output vpc_id

# JSON format output
terraform output -json

# sensitive output ကြည့်ရန်
terraform output -raw db_password
```

### Workspace

```bash
# workspace list
terraform workspace list

# workspace create
terraform workspace new staging

# workspace switch
terraform workspace select prod

# current workspace ကြည့်ရန်
terraform workspace show

# workspace delete
terraform workspace delete staging
```

### Miscellaneous

```bash
# installed providers ကြည့်ရန်
terraform providers

# dependency graph (dot format)
terraform graph | dot -Tpng > graph.png

# state lock ကို force release (ဂရုစိုက်ပါ)
terraform force-unlock LOCK_ID

# console (expression testing)
terraform console
# > aws_instance.app.private_ip
# > var.environment
```

---

## Naming Convention

Consistent naming pattern:

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# resources
"${local.name_prefix}-vpc"
"${local.name_prefix}-app-sg"
"${local.name_prefix}-mysql"
"${local.name_prefix}-alb"
```

AWS Console မှာ resource ရှာရလွယ်ပြီး cost tracking အတွက်လည်းကောင်းပါတယ်။

---

## Security Best Practices

```hcl
# 1. Encryption everywhere
resource "aws_db_instance" "main" {
  storage_encrypted = true
}

resource "aws_instance" "app" {
  root_block_device {
    encrypted = true
  }
}

# 2. Least privilege security groups
resource "aws_security_group_rule" "db_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id   # not 0.0.0.0/0
  security_group_id        = aws_security_group.db.id
}

# 3. Private resources
resource "aws_db_instance" "main" {
  publicly_accessible = false
}

# 4. VPC flow logs
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}
```

Git safety:

```gitignore
# .gitignore
*.tfstate
*.tfstate.backup
*.tfvars
.terraform/
.terraform.lock.hcl   # optional - team ကသုံးရင် commit လုပ်ပြီး version pin လုပ်တာကောင်းတယ်
*.pem
*.key
```

---

## Quick Mental Model

```text
.tf files        = ကိုယ်လိုချင်တဲ့ infrastructure design
provider         = AWS API နဲ့ချိတ်တဲ့ driver
state            = Terraform သိထားတဲ့ real resource map
plan             = ဘာပြောင်းမလဲ preview (apply မလုပ်ရသေးဘူး)
apply            = AWS မှာတကယ်ပြောင်းခြင်း
destroy          = Terraform manage လုပ်ထားတဲ့ resources ဖျက်ခြင်း
module           = reusable Terraform folder/component
resource         = real infrastructure object (EC2, VPC, RDS)
data source      = existing information lookup (create မလုပ်ပါ)
variable         = external input value
local            = internal computed value
output           = module/stack ကနေ expose လုပ်တဲ့ value
implicit dep     = attribute reference ကြောင့် order ကိုအလိုအလျောက်သိတာ
explicit dep     = depends_on နဲ့ကိုယ်တိုင်သတ်မှတ်တဲ့ order
drift            = code/state နဲ့ real AWS မကိုက်တော့တဲ့ state
import           = existing resource ကို Terraform management ထဲသွင်းတာ
```

Terraform သင်တဲ့အခါ အရေးကြီးဆုံးက **`terraform plan` output ကိုဖတ်တတ်ဖို့**ပါ။ Code ရေးတတ်တာထက် plan က infrastructure ကိုဘယ်လိုပြောင်းမလဲ နားလည်တာက real-world မှာပိုအရေးကြီးပါတယ်။