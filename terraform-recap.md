# Terraform Recap - DevOps Bootcamp

ဒီ document က Terraform ကို bootcamp အတွက် Burmese ဖြင့် recap လုပ်ထားတာပါ။ ဒီ repo ထဲက AWS WordPress infrastructure project ကိုအခြေခံပြီး Terraform ဘယ်လိုအလုပ်လုပ်လဲ၊ root module/child module ဆိုတာဘာလဲ၊ resource block တွေကို ဘယ်လိုနားလည်ရမလဲ၊ implicit/explicit dependency ဆိုတာဘာလဲ စတာတွေကို practical view နဲ့ရှင်းထားပါတယ်။

## Terraform ဆိုတာဘာလဲ

Terraform က Infrastructure as Code tool တစ်ခုပါ။ AWS console ထဲ manual click လုပ်ပြီး VPC, EC2, RDS, ALB စတာတွေ create လုပ်မယ့်အစား `.tf` files ထဲမှာ infrastructure ကို code အနေနဲ့ရေးပြီး Terraform က create/update/delete လုပ်ပေးပါတယ်။

Terraform workflow အခြေခံက:

```text
Write .tf files
  -> terraform init
  -> terraform validate
  -> terraform plan
  -> terraform apply
  -> Terraform state update
```

အဓိက idea က desired state ပါ။ ကိုယ်လိုချင်တဲ့ infrastructure state ကို code ထဲရေးထားပြီး Terraform က real AWS state နဲ့နှိုင်းယှဉ်ကာ ဘာပြောင်းရမလဲတွက်ပေးပါတယ်။

## Terraform ဘယ်လိုအလုပ်လုပ်လဲ

Terraform run တဲ့အခါ အကြမ်းဖျင်းဒီလိုအလုပ်လုပ်ပါတယ်။

1. `.tf` files တွေကိုဖတ်တယ်။
2. Provider config ကိုဖတ်ပြီး AWS provider plugin ကိုသုံးတယ်။
3. Variables တွေကို resolve လုပ်တယ်။
4. Resource dependency graph တည်ဆောက်တယ်။
5. State file ထဲက အရင် infrastructure state ကိုဖတ်တယ်။
6. AWS API ကိုခေါ်ပြီး current real infrastructure ကိုစစ်တယ်။
7. Desired state နဲ့ current state ကို compare လုပ်တယ်။
8. Plan ထုတ်တယ်။
9. Apply လုပ်ရင် AWS API ကိုခေါ်ပြီး resource တွေ create/update/delete လုပ်တယ်။
10. State file ကို update လုပ်တယ်။

Terraform က shell script မဟုတ်ပါ။ Line by line အစဉ်လိုက် run တာမဟုတ်ဘဲ dependency graph အတိုင်း resource order ကိုဆုံးဖြတ်ပါတယ်။

## Terraform Folder Structure

ဒီ bootcamp project မှာ Terraform structure ကဒီလိုပါ။

```text
terraform/
  environments/
    dev/
      main.tf
      variables.tf
      outputs.tf
      providers.tf
      backend.tf
      versions.tf
  modules/
    vpc/
    iam/
    ec2/
    rds/
    alb/
    waf/
    sns/
    cloudwatch/
```

`terraform/environments/dev/` က dev environment အတွက် root module ပါ။

`terraform/modules/` ထဲက folders တွေက reusable child modules တွေပါ။

## Root Module

Root module ဆိုတာ `terraform init`, `terraform plan`, `terraform apply` run လုပ်တဲ့ main Terraform folder ကိုဆိုလိုပါတယ်။

ဒီ repo မှာ dev environment အတွက် root module က:

```text
terraform/environments/dev
```

Root module ထဲမှာ provider, backend, variables, outputs, child module calls တွေရှိပါတယ်။

ဥပမာ:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}
```

ဒီ code က `../../modules/vpc` child module ကို root module ကနေခေါ်တာပါ။

## Child Module

Child module ဆိုတာ reusable Terraform code block/folder ပါ။ VPC, EC2, RDS စတဲ့ infrastructure piece တစ်ခုချင်းစီကို module အဖြစ်ခွဲထားရင် code ပိုရှင်းပြီး maintain လုပ်ရလွယ်ပါတယ်။

ဥပမာ:

- `modules/vpc`: VPC, subnet, route table, NAT gateway
- `modules/iam`: EC2 instance role, SSM permissions
- `modules/ec2`: WordPress EC2 instance
- `modules/rds`: RDS MySQL, DB subnet group, DB security group
- `modules/alb`: Application Load Balancer
- `modules/waf`: WAF web ACL

Root module က child module ကိုခေါ်တဲ့အခါ `module` block သုံးပါတယ်။

```hcl
module "ec2" {
  source = "../../modules/ec2"

  subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id = module.alb.ec2_security_group_id
}
```

ဒီမှာ `module.ec2` ဆိုတာ root module ကခေါ်ထားတဲ့ child module instance name ပါ။

## Resource Block

Terraform resource block က real infrastructure object တစ်ခုကို represent လုပ်ပါတယ်။

Syntax:

```hcl
resource "RESOURCE_TYPE" "LOCAL_NAME" {
  argument = value
}
```

ဥပမာ:

```hcl
resource "aws_instance" "wordpress" {
  ami           = data.aws_ami.wordpress.id
  instance_type = var.instance_type

  tags = {
    Name = "${var.project_name}-${var.environment}-wordpress"
  }
}
```

ဒီမှာ:

- `resource`: Terraform block keyword
- `aws_instance`: resource type, AWS EC2 instance ကိုဆိုလိုတယ်
- `wordpress`: Terraform local resource name
- `ami`, `instance_type`, `tags`: resource arguments

`wordpress` ဆိုတဲ့ local name က AWS console ထဲက Name မဟုတ်ပါ။ Terraform code ထဲမှာ reference လုပ်ဖို့သုံးတဲ့ label ပါ။

AWS console ထဲမှာမြင်ရမယ့် name ကများသောအားဖြင့် `tags.Name` ဖြစ်ပါတယ်။

## Resource Address

Terraform က resource တစ်ခုကို address နဲ့ခေါ်ပါတယ်။

Root module ထဲက resource address:

```text
aws_instance.wordpress
```

Child module ထဲက resource address:

```text
module.ec2.aws_instance.wordpress
```

Nested module ဖြစ်ရင်:

```text
module.parent.module.child.aws_instance.wordpress
```

CLI မှာ resource ကိုသီးသန့်ကြည့်ချင်ရင်:

```bash
terraform state show module.ec2.aws_instance.wordpress
```

Plan မှာ resource address တွေမြင်ရတာက Terraform ဘယ် object ကိုပြောင်းမလဲသိဖို့အရေးကြီးပါတယ်။

## Resource Name vs AWS Name

Terraform learner တွေအတွက် ရှုပ်တတ်တဲ့အချက်တစ်ခုက resource name နဲ့ AWS resource name မတူတာပါ။

```hcl
resource "aws_security_group" "web" {
  name = "devops-bootcamp-dev-web-sg"

  tags = {
    Name = "devops-bootcamp-dev-web-sg"
  }
}
```

ဒီမှာ:

- `aws_security_group`: Terraform resource type
- `web`: Terraform local name
- `name`: AWS security group name argument
- `tags.Name`: AWS console မှာမြင်ရတဲ့ Name tag

Terraform code ထဲမှာ reference လုပ်ရင်:

```hcl
aws_security_group.web.id
```

AWS console မှာရှာရင်:

```text
devops-bootcamp-dev-web-sg
```

## Arguments and Attributes

Resource block ထဲမှာ ကိုယ်ပေးတဲ့ values တွေကို arguments လို့ခေါ်ပါတယ်။

```hcl
resource "aws_instance" "wordpress" {
  ami           = "ami-123456"
  instance_type = "t3a.small"
}
```

ဒီမှာ `ami` နဲ့ `instance_type` က arguments ပါ။

Terraform apply ပြီးမှ provider ကပြန်ပေးတဲ့ values တွေကို attributes လို့ခေါ်ပါတယ်။

ဥပမာ:

```hcl
aws_instance.wordpress.id
aws_instance.wordpress.private_ip
aws_instance.wordpress.arn
```

ဒီ attributes တွေကို တခြား resource တွေမှာ reference လုပ်လို့ရပါတယ်။

## Data Source

Resource က infrastructure ကို create/manage လုပ်ပါတယ်။ Data source က existing information ကိုဖတ်ပါတယ်။

ဥပမာ Packer က build ထားတဲ့ AMI ကို Terraform ကရှာချင်ရင် data source သုံးနိုင်ပါတယ်။

```hcl
data "aws_ami" "wordpress" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Project"
    values = ["devops-bootcamp"]
  }

  filter {
    name   = "tag:ImageRole"
    values = ["wordpress-lemp"]
  }
}
```

Reference လုပ်ရင်:

```hcl
data.aws_ami.wordpress.id
```

Data source က resource အသစ်မဖန်တီးပါဘူး။ Existing AWS data ကို lookup လုပ်တာပါ။

## Implicit Dependency

Implicit dependency ဆိုတာ Terraform က reference ကိုကြည့်ပြီး dependency ကိုအလိုအလျောက်သိတာပါ။

ဥပမာ:

```hcl
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

`aws_subnet.public` က `aws_vpc.main.id` ကို reference လုပ်ထားတဲ့အတွက် Terraform က VPC ကိုအရင် create လုပ်ပြီးမှ subnet ကို create လုပ်ရမယ်လို့သိပါတယ်။

ဒီလို reference dependency ကို implicit dependency လို့ခေါ်ပါတယ်။

နောက်ဥပမာ:

```hcl
resource "aws_instance" "wordpress" {
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.wordpress.id]
}
```

ဒီ instance က subnet နဲ့ security group ကိုသုံးထားတဲ့အတွက် Terraform က subnet/security group မပြီးခင် EC2 ကိုမဆောက်ပါ။

Best practice: ဖြစ်နိုင်သမျှ implicit dependency ကိုသုံးပါ။ Attribute reference လုပ်တာက Terraform graph အတွက်ရှင်းပါတယ်။

## Explicit Dependency

Explicit dependency ဆိုတာ `depends_on` နဲ့ dependency ကိုကိုယ်တိုင်ပြောတာပါ။

```hcl
resource "aws_instance" "wordpress" {
  ami           = data.aws_ami.wordpress.id
  instance_type = var.instance_type

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]
}
```

ဒီလိုရေးရင် Terraform က `aws_iam_role_policy_attachment.ssm` ပြီးမှ `aws_instance.wordpress` ကိုလုပ်မယ်။

`depends_on` ကို ဘယ်အချိန်သုံးသင့်လဲ:

- Resource တစ်ခုက တခြား resource ကို တိုက်ရိုက် attribute reference မလုပ်ပေမယ့် real-world မှာ order လိုတဲ့အခါ
- IAM policy attachment ပြီးမှ service တစ်ခု start ဖြစ်စေချင်တဲ့အခါ
- AWS eventually consistent behavior ကြောင့် order ပြတ်သားစေချင်တဲ့အခါ

သတိထားရန်:

- `depends_on` ကိုအများကြီးမသုံးသင့်ပါ။
- Reference နဲ့ဖြေရှင်းလို့ရရင် reference ကိုသုံးပါ။
- `depends_on` များလွန်းရင် Terraform graph ပိုရှုပ်ပြီး plan/apply နှေးနိုင်ပါတယ်။

## Variables

Variables က Terraform code ကို reusable ဖြစ်အောင်လုပ်ပေးပါတယ်။

```hcl
variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}
```

သုံးတဲ့အခါ:

```hcl
tags = {
  Environment = var.environment
}
```

Variable value ပေးနိုင်တဲ့နည်းလမ်းတွေ:

- `default` value
- `terraform.tfvars`
- `*.auto.tfvars`
- CLI `-var`
- environment variable `TF_VAR_name`
- CI secret ကနေ file generate လုပ်ခြင်း

ဒီ repo rule အရ real secrets ပါတဲ့ `terraform.tfvars` ကို Git ထဲ commit မလုပ်ရပါ။

## Outputs

Output က Terraform apply ပြီးနောက် user သို့တခြား module သို့ပြန်ပေးချင်တဲ့ value တွေပါ။

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

Child module output ကို root module က reference လုပ်နိုင်ပါတယ်။

```hcl
module.vpc.vpc_id
module.rds.db_endpoint
```

Output ကိုလိုအပ်မှထည့်ပါ။ Secret value တွေကို output မလုပ်သင့်ပါ။

## Providers

Provider က Terraform နဲ့ cloud/service API ကြား connector ပါ။

AWS resource တွေ create လုပ်ဖို့ AWS provider ကိုသုံးပါတယ်။

```hcl
provider "aws" {
  region = var.aws_region
}
```

Provider က AWS API ကိုခေါ်ဖို့ credentials လိုပါတယ်။ Local machine မှာ AWS profile သုံးနိုင်ပြီး CI မှာ GitHub Secrets က credentials သုံးနိုင်ပါတယ်။

## Backend and State

Terraform state က Terraform က manage လုပ်နေတဲ့ real resources information ကိုသိမ်းထားတဲ့ file/database ပါ။

State ထဲမှာ resource IDs, attributes, dependency info တွေပါနိုင်ပါတယ်။ Sensitive value တွေလည်းပါနိုင်တာကြောင့် state ကိုဂရုစိုက်ရပါတယ်။

Local state:

```text
terraform.tfstate
```

Remote state:

```text
S3 backend + DynamoDB locking
```

Team project မှာ remote state ကပိုကောင်းပါတယ်။

Remote backend အကျိုးကျေးဇူး:

- Team members အားလုံး same state ကိုသုံးနိုင်တယ်။
- Local computer ပျက်လည်း state မပျောက်ဘူး။
- Locking ပါရင် တစ်ချိန်တည်း apply နှစ်ခုမလုပ်အောင်ကာကွယ်နိုင်တယ်။

State file ကို Git ထဲ commit မလုပ်ပါနဲ့။

## Terraform Plan

`terraform plan` က apply မလုပ်ခင် ဘာပြောင်းမလဲ preview ပြတာပါ။

Plan symbols:

```text
+ create
~ update in-place
- destroy
-/+ replace
```

Plan ဖတ်တဲ့အခါ အရေးကြီးတာ:

- Destroy ဖြစ်မယ့် resource ရှိလား။
- Replace ဖြစ်မယ့် database/EC2 ရှိလား။
- Security group rule တွေမှန်လား။
- Public access မလိုဘဲဖွင့်မိလား။
- RDS publicly accessible ဖြစ်နေသလား။

Real-world မှာ plan ကိုမဖတ်ဘဲ apply မလုပ်သင့်ပါ။

## Terraform Apply

`terraform apply` က plan ထဲက changes တွေကို တကယ် AWS မှာလုပ်ပါတယ်။

```bash
terraform apply
```

Saved plan ကို apply ချင်ရင်:

```bash
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan
```

CI မှာ apply stage ကို manual approval နဲ့ထားတာက ပိုကောင်းပါတယ်။ Apply က real infrastructure ကိုပြောင်းနိုင်လို့ပါ။

## Terraform Destroy

`terraform destroy` က Terraform manage လုပ်ထားတဲ့ resource တွေကိုဖျက်ပါတယ်။

Bootcamp/test environment မှာ cost save ဖို့ destroy သုံးနိုင်ပေမယ့် production မှာ အလွန်သတိထားရပါမယ်။

Destroy မလုပ်ခင်စစ်ရန်:

- RDS backup/snapshot လိုလား။
- S3 bucket ထဲ data ရှိလား။
- DNS record တွေ production traffic ကိုသက်ရောက်လား။
- State/backend မှန်တဲ့ environment ကိုသုံးနေလား။

## Module Input and Output Flow

Root module က child module ကို input ပေးတယ်။ Child module က output ပြန်ပေးတယ်။

```text
root module
  -> passes variables to module.vpc
  -> module.vpc creates VPC/subnets
  -> module.vpc outputs subnet IDs
  -> root module passes subnet IDs to module.ec2/module.rds
```

ဥပမာ:

```hcl
module "rds" {
  source = "../../modules/rds"

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}
```

ဒီမှာ `module.rds` က `module.vpc` output ကိုသုံးတဲ့အတွက် implicit dependency ဖြစ်ပါတယ်။ Terraform က VPC module resources တွေလိုအပ်သလိုပြီးမှ RDS module ကိုဆက်လုပ်ပါမယ်။

## Count and For_each

Resource တစ်ခုကို multiple copies create လုပ်ချင်ရင် `count` သို့ `for_each` သုံးပါတယ်။

`count` ဥပမာ:

```hcl
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  cidr_block = var.public_subnet_cidrs[count.index]
}
```

`for_each` ဥပမာ:

```hcl
resource "aws_security_group_rule" "ingress" {
  for_each = var.allowed_ports

  from_port = each.value
  to_port   = each.value
  protocol  = "tcp"
}
```

Real-world advice:

- Simple list အတွက် `count` သုံးလို့ရတယ်။
- Stable named items အတွက် `for_each` ပိုကောင်းတတ်တယ်။
- List order ပြောင်းရင် `count` resource address တွေပြောင်းနိုင်လို့ replacement ဖြစ်နိုင်ပါတယ်။

## Lifecycle

`lifecycle` block က Terraform resource behavior ကိုထိန်းချုပ်ဖို့သုံးပါတယ်။

ဥပမာ:

```hcl
resource "aws_db_instance" "mysql" {
  identifier = "devops-bootcamp-dev-mysql"

  lifecycle {
    prevent_destroy = true
  }
}
```

`prevent_destroy = true` ထားရင် accident destroy ကိုကာကွယ်နိုင်ပါတယ်။ Production database တွေအတွက်အသုံးဝင်ပါတယ်။

Common lifecycle options:

- `prevent_destroy`: resource မဖျက်အောင်ကာကွယ်တယ်။
- `create_before_destroy`: replacement လုပ်တဲ့အခါ အသစ်ကိုအရင် create လုပ်တယ်။
- `ignore_changes`: Terraform ကတချို့ external changes တွေကို ignore လုပ်စေတယ်။

သတိထားရန်: `ignore_changes` ကိုအလွယ်မသုံးပါနဲ့။ Drift ကိုဖုံးကွယ်သွားနိုင်ပါတယ်။

## Drift

Drift ဆိုတာ Terraform code/state နဲ့ real AWS resource မကိုက်တော့တာပါ။

ဥပမာ:

- Terraform က security group port 80 ပဲဖွင့်ထားတယ်။
- တစ်ယောက်က AWS console ထဲကနေ port 22 ကို manual ထပ်ဖွင့်တယ်။
- အခု real AWS state က Terraform code နဲ့မကိုက်တော့ဘူး။

`terraform plan` run လုပ်ရင် drift ကိုပြနိုင်ပါတယ်။ Real-world မှာ infrastructure ကို console ကနေ manual မပြင်ဘဲ Terraform ကနေပြင်တာကပိုကောင်းပါတယ်။

## Import

ရှိပြီးသား AWS resource ကို Terraform state ထဲထည့်ချင်ရင် `terraform import` သုံးနိုင်ပါတယ်။

```bash
terraform import aws_vpc.main vpc-1234567890abcdef0
```

Import လုပ်တာက resource ကို create မလုပ်ပါဘူး။ Existing resource ကို Terraform state ထဲချိတ်တာပါ။ Import ပြီးရင် `.tf` code ကို real resource configuration နဲ့ကိုက်အောင်ရေးရပါမယ်။

## Naming Convention

ဒီ repo မှာ resource name တွေကို ဒီ pattern နဲ့ထားတာကောင်းပါတယ်။

```text
${var.project_name}-${var.environment}-resource-purpose
```

ဥပမာ:

```text
devops-bootcamp-dev-vpc
devops-bootcamp-dev-wordpress
devops-bootcamp-dev-rds
```

Name consistent ဖြစ်ရင် AWS console ထဲမှာရှာရလွယ်ပြီး cost/resource tracking ပိုကောင်းပါတယ်။

## Tags

Tags က AWS resource organization အတွက်အရေးကြီးပါတယ်။

Common tags:

```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  ManagedBy   = "terraform"
}
```

Tags အသုံးဝင်တဲ့နေရာတွေ:

- Cost Explorer filtering
- Resource search
- Automation
- Ownership tracking
- Cleanup

## Security Best Practices

Terraform code ရေးတဲ့အခါ security ကိုစဉ်းစားရပါမယ်။

အရေးကြီးတဲ့ points:

- Secrets ကို Git ထဲမထည့်ပါနဲ့။
- `.tfvars`, `.tfstate`, `.pem`, `.key` files တွေကို commit မလုပ်ပါနဲ့။
- EC2 ကို private subnet ထဲထားနိုင်ရင် ပိုကောင်းပါတယ်။
- SSH ကို public internet မှာမဖွင့်ဘဲ SSM Session Manager သုံးပါ။
- RDS ကို private subnet ထဲထားပြီး `publicly_accessible = false` ထားပါ။
- Security group ingress rule ကိုလိုအပ်သလောက်ပဲဖွင့်ပါ။
- WAF/ALB/CloudWatch alarm တွေကို production နီးပါး setup မှာထည့်ပါ။

## Common Terraform Commands

Root module folder ထဲမှာ run ပါ။

```bash
cd terraform/environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Backend မချိတ်ဘဲ validation-only လုပ်ချင်ရင်:

```bash
terraform init -backend=false
terraform validate
```

State resource list ကြည့်ရန်:

```bash
terraform state list
```

Resource တစ်ခု detail ကြည့်ရန်:

```bash
terraform state show module.ec2.aws_instance.wordpress
```

## CI/CD မှာ Terraform

ဒီ project ရဲ့ Terraform CI ကို manual dispatch အဖြစ်ထားပါတယ်။

Stage တွေ:

- `validate`: Terraform init no backend + validate
- `plan`: remote backend init + plan + artifact upload
- `apply`: plan အသစ်ထုတ်ပြီး apply

ဘာကြောင့် manual stage by stage ထားလဲ:

- Infrastructure changes ကို auto apply မလုပ်ချင်လို့
- Plan ကိုဖတ်ပြီးမှ apply လုပ်ချင်လို့
- AWS cost/security impact ရှိနိုင်လို့
- Bootcamp မှာ stage တစ်ခုချင်းနားလည်စေချင်လို့

## Real-world Workflow

Team project မှာ Terraform workflow ကိုဒီလိုသွားတာများပါတယ်။

```text
Developer edits Terraform code
  -> terraform fmt
  -> terraform validate
  -> pull request
  -> CI plan
  -> team reviews plan
  -> manual approval
  -> apply
  -> monitor CloudWatch/AWS console
```

Production မှာ direct `terraform apply` ကို local machine ကနေမလုပ်ဘဲ CI/CD runner ကနေ approval နဲ့လုပ်တာပိုကောင်းပါတယ်။

## Troubleshooting

Plan မှာ AMI မတွေ့ရင်:

- Packer build ပြီးပြီလား။
- Packer AMI tags မှန်လား။
- Terraform region/account က Packer build account နဲ့တူလား။

Backend init fail ဖြစ်ရင်:

- S3 backend bucket ရှိလား။
- AWS credentials မှန်လား။
- Region မှန်လား။
- State lock table သုံးထားရင် DynamoDB permission ရှိလား။

Provider error ဖြစ်ရင်:

- `terraform init` ပြန် run ပါ။
- `.terraform.lock.hcl` version conflict ရှိမရှိစစ်ပါ။
- CI မှာ network/plugin download access ရှိမရှိစစ်ပါ။

Plan က resource destroy ပြမယ်ဆိုရင်:

- Variable value ပြောင်းသွားလား။
- Resource name/identifier ပြောင်းသွားလား။
- State backend မှားနေသလား။
- Workspace/environment မှားနေသလား။

## Quick Mental Model

Terraform ကိုဒီလိုမှတ်ပါ။

```text
.tf files = ကိုယ်လိုချင်တဲ့ infrastructure design
provider = AWS API နဲ့ချိတ်တဲ့ driver
state = Terraform သိထားတဲ့ real resource map
plan = ဘာပြောင်းမလဲ preview
apply = AWS မှာတကယ်ပြောင်းခြင်း
module = reusable Terraform folder
resource = real infrastructure object
data source = existing information lookup
implicit dependency = reference ကြောင့် Terraform အလိုအလျောက်သိတဲ့ order
explicit dependency = depends_on နဲ့ကိုယ်တိုင်သတ်မှတ်တဲ့ order
```

Terraform သင်တဲ့အခါ အရေးကြီးဆုံးက plan ကိုဖတ်တတ်ဖို့ပါ။ Code ရေးတတ်တာထက် `terraform plan` က infrastructure ကိုဘယ်လိုပြောင်းမလဲနားလည်တာက real-world DevOps မှာပိုအရေးကြီးပါတယ်။
