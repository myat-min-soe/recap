# DevOps Bootcamp Docs

DevOps Bootcamp အတွက် recap/review notes တွေစုထားတဲ့နေရာပါ။ Linux server basics, AWS infrastructure services, Terraform Infrastructure as Code concepts တွေကို lab မလုပ်ခင်၊ lab လုပ်နေချိန်၊ ပြန်လေ့လာချိန်မှာ quick reference အနေနဲ့သုံးနိုင်ပါတယ်။

## Documents

| File | Review focus |
| --- | --- |
| [linux-recap.md](./linux-recap.md) | Linux command line, filesystem, permissions, services, logs, Nginx, PHP-FPM, MySQL client, troubleshooting |
| [aws-recap.md](./aws-recap.md) | VPC, ALB, EC2, RDS, IAM, WAF, Security Groups, CloudWatch, SNS, ACM, Route 53, S3 |
| [terraform-recap.md](./terraform-recap.md) | Terraform workflow, modules, resources, variables, outputs, state, plan/apply, import, workspaces, security best practices |

## Suggested Review Order

1. Read [linux-recap.md](./linux-recap.md) first to understand server operation basics.
2. Read [aws-recap.md](./aws-recap.md) next to understand the AWS resources used in the infrastructure.
3. Read [terraform-recap.md](./terraform-recap.md) last to understand how those resources are created and managed as code.

## How To Use These Notes

- Use them as a quick refresher before running Terraform or Packer labs.
- Copy only safe example commands; do not copy real secrets into tracked files.
- When debugging, start from Linux service/log checks, then AWS resource checks, then Terraform state/plan checks.
- Update these notes when a lab teaches a new pattern, command, or troubleshooting lesson.
