# AWS Services Recap - DevOps Bootcamp

ဒီ document က WordPress + LEMP + Terraform project အတွက် အသုံးပြုမယ့် AWS service တွေကို Burmese ဖြင့် အသေးစိတ် recap လုပ်ထားတာပါ။

## Architecture အကျဉ်းချုပ်

ဒီ project ရဲ့ goal က WordPress site တစ်ခုကို AWS ပေါ်မှာ production နီးပါး architecture နဲ့ deploy လုပ်နိုင်ဖို့ပါ။

Flow က ဒီလိုသွားမယ်။

```text
User
  -> Route 53 DNS
  -> CloudFront or ALB
  -> AWS WAF
  -> EC2 Ubuntu 24.04, Nginx, PHP-FPM, WordPress
  -> RDS MySQL
  -> S3 media bucket
  -> CloudWatch metrics/logs
```

Terraform က infrastructure တွေကို code အနေနဲ့ create/update/destroy လုပ်ပေးမယ်။

## 1. VPC

VPC ဆိုတာ AWS account ထဲမှာ ကိုယ်ပိုင် virtual network တစ်ခုဆောက်တာပါ။ EC2, RDS, NAT Gateway, Load Balancer စတဲ့ resource တွေကို VPC ထဲမှာထားပြီး network control လုပ်နိုင်တယ်။

ဒီ bootcamp မှာ VPC ထဲမှာ public subnet နဲ့ private subnet ခွဲထားမယ်။

Public subnet:

- Internet Gateway နဲ့ ချိတ်ထားတယ်။
- Internet ကနေ တိုက်ရိုက်ဝင်နိုင်တဲ့ resource တွေထားတယ်။
- ဥပမာ EC2 public WordPress server, NAT Gateway, ALB။

Private subnet:

- Internet ကနေ တိုက်ရိုက်ဝင်လို့မရဘူး။
- Database လို sensitive resource တွေထားတယ်။
- ဥပမာ RDS MySQL။

အရေးကြီးတဲ့ concept တွေ:

- CIDR block: VPC/Subnet ရဲ့ IP range ဖြစ်တယ်။ ဥပမာ `10.0.0.0/16`
- Route table: traffic ဘယ်ကိုသွားမလဲ သတ်မှတ်တယ်။
- Internet Gateway: public subnet က internet ထွက်/ဝင်နိုင်အောင်လုပ်တယ်။
- NAT Gateway: private subnet ထဲက resource တွေ internet ထွက်နိုင်အောင်လုပ်တယ်။ ဒါပေမယ့် internet ကနေ private resource ကို တိုက်ရိုက်ဝင်လို့မရဘူး။

ဒီ project မှာ VPC module က public/private subnet, internet gateway, NAT gateway, route table တွေကို create လုပ်ဖို့ဖြစ်တယ်။

## 2. EC2

EC2 ဆိုတာ AWS ပေါ်က virtual machine ပါ။ ဒီ project မှာ EC2 ကို WordPress application server အဖြစ်သုံးမယ်။

EC2 ပေါ်မှာ install လုပ်မယ့် stack:

- Ubuntu 24.04
- Nginx
- PHP 8.3 / PHP-FPM
- WordPress files
- MySQL client

ဒီ project မှာ EC2 instance type ကို `t3a.small` သုံးထားတယ်။ Bootcamp/practice အတွက် `t3.micro` ထက် နည်းနည်း memory ပိုရပြီး WordPress test လုပ်ရတာ ပိုအဆင်ပြေတယ်။

EC2 အတွက် security group:

- SSH port `22`: ကိုယ့် IP ကနေသာဝင်ခွင့်ပေးသင့်တယ်။
- HTTP port `80`: ALB/CloudFront ကနေလာတဲ့ traffic အတွက်ဖွင့်တယ်။
- Outbound: package install, WordPress download, update တွေအတွက် internet ထွက်ခွင့်ပေးတယ်။

Best practice:

- SSH key pair နဲ့ login ဝင်ပါ။
- Password login မသုံးပါနဲ့။
- Security group မှာ SSH ကို `0.0.0.0/0` မဖွင့်ပါနဲ့။
- Application config, password, DB credential တွေကို Git ထဲမထည့်ပါနဲ့။

## 3. RDS

RDS ဆိုတာ managed database service ပါ။ ကိုယ်တိုင် MySQL server install/manage လုပ်စရာမလိုဘဲ AWS က database patching, backup, storage management တချို့ကို manage လုပ်ပေးတယ်။

ဒီ project မှာ RDS MySQL ကို WordPress database အဖြစ်သုံးမယ်။

RDS design:

- Private subnet ထဲမှာထားမယ်။
- Publicly accessible ကို `false` ထားမယ်။
- EC2 security group ကနေ MySQL port `3306` ကိုပဲ allow လုပ်မယ်။
- Storage encrypted ထားမယ်။
- Backup retention ထားမယ်။

ဒီ project မှာ RDS instance class ကို `db.t4g.micro` သုံးထားတယ်။ ဒါက ARM/Graviton based small database instance ဖြစ်ပြီး bootcamp/test workload အတွက် သင့်တော်တယ်။

WordPress က RDS ကို connect လုပ်ဖို့လိုမယ့် info:

- DB host: RDS endpoint
- DB name: `wordpress`
- DB user: `wordpress`
- DB password: secret value

သတိထားရန်:

- RDS password ကို `.tfvars` ထဲထည့်ရင် Git ထဲ commit မလုပ်ပါနဲ့။
- Production မှာ AWS Secrets Manager သို့ Parameter Store သုံးတာပိုကောင်းတယ်။
- Delete protection ကို production မှာ enable ထားသင့်တယ်။

## 4. S3

S3 ဆိုတာ object storage service ပါ။ File, image, backup, log, Terraform state စတာတွေကို သိမ်းဖို့သုံးတယ်။

ဒီ project မှာ S3 ကို နှစ်မျိုးသုံးနိုင်တယ်။

WordPress media uploads:

- WordPress uploaded images/files တွေကို S3 bucket ထဲ သိမ်းနိုင်တယ်။
- CloudFront နဲ့တွဲသုံးရင် media delivery ပိုမြန်နိုင်တယ်။
- WordPress plugin တစ်ခုဖြင့် S3 offload လုပ်နိုင်တယ်။

Terraform remote state:

- Terraform state file ကို local machine ထဲမထားဘဲ S3 bucket ထဲ သိမ်းနိုင်တယ်။
- Team project ဖြစ်လာရင် remote state အရေးကြီးတယ်။
- DynamoDB table နဲ့ state locking လုပ်နိုင်တယ်။

S3 best practice:

- Public access block ကို default enable ထားပါ။
- Bucket policy ကို လိုအပ်သလောက်ပဲဖွင့်ပါ။
- Versioning enable ထားရင် mistake recovery ပိုကောင်းတယ်။
- Terraform state bucket ကို encrypted ထားပါ။

## 5. CloudFront

CloudFront ဆိုတာ AWS CDN service ပါ။ User နဲ့ နီးတဲ့ edge location ကနေ content ပြန်ပေးနိုင်လို့ site speed ပိုကောင်းတယ်။

WordPress project မှာ CloudFront ကို ဒီလိုသုံးနိုင်တယ်။

- WordPress site အတွက် CDN layer
- Static assets cache
- S3 media bucket cache
- HTTPS certificate integration
- WAF attach လုပ်နိုင်တဲ့ edge layer

Origin ဆိုတာ CloudFront က content သွားယူမယ့် backend ပါ။

Possible origins:

- EC2 public DNS
- ALB DNS name
- S3 bucket

Production နီးပါး design မှာ CloudFront -> ALB -> EC2 ဆိုတာ ပိုကောင်းတယ်။ Bootcamp simple setup မှာ CloudFront -> EC2 လည်းလုပ်နိုင်တယ်။

သတိထားရန်:

- WordPress admin page `/wp-admin` ကို cache မလုပ်သင့်ဘူး။
- Login, cart, admin, preview path တွေ cache policy သီးသန့်လိုနိုင်တယ်။
- HTTPS ကို CloudFront/ALB မှာ terminate လုပ်ရင် WordPress `siteurl` နဲ့ forwarded header config မှန်ဖို့လိုတယ်။

## 6. AWS WAF

AWS WAF ဆိုတာ web application firewall ပါ။ HTTP request တွေကို inspect လုပ်ပြီး attack traffic ကို block/count/allow လုပ်နိုင်တယ်။

WordPress အတွက် useful ဖြစ်တဲ့ rule တွေ:

- AWSManagedRulesWordPressRuleSet
- AWSManagedRulesPHPRuleSet
- AWSManagedRulesSQLiRuleSet
- AWSManagedRulesKnownBadInputsRuleSet
- AWSManagedRulesAmazonIpReputationList
- Rate-based rule

ဒီ project မှာ WAF ကို WordPress-compatible ဖြစ်အောင် configure လုပ်ထားတယ်။

အရေးကြီးတဲ့ point:

- WordPress upload တွေအတွက် body size rule က false positive ဖြစ်နိုင်တယ်။
- ဒီအတွက် `SizeRestrictions_BODY` ကို `count` mode ထားထားတယ်။
- Count mode ဆိုတာ block မလုပ်သေးဘဲ log/metric ကြည့်ဖို့ကောင်းတယ်။
- Traffic pattern နားလည်လာမှ block mode ပြောင်းတာ ပိုကောင်းတယ်။

WAF logging:

- WAF log တွေကို CloudWatch Log Group ထဲပို့ထားတယ်။
- Log group name က `aws-waf-logs-...` prefix နဲ့ရှိရမယ်။
- Logs Insights နဲ့ query လုပ်ပြီး blocked request, IP, URI, rule name တွေကြည့်နိုင်တယ်။

CloudWatch Logs Insights sample query:

```sql
fields @timestamp, action, httpRequest.clientIp, httpRequest.country, httpRequest.uri, terminatingRuleId
| sort @timestamp desc
| limit 50
```

Blocked request တွေပဲကြည့်ချင်ရင်:

```sql
fields @timestamp, httpRequest.clientIp, httpRequest.uri, terminatingRuleId
| filter action = "BLOCK"
| sort @timestamp desc
| limit 50
```

## 7. CloudWatch

CloudWatch က monitoring နဲ့ observability service ပါ။

အသုံးများတာတွေ:

- Metrics
- Logs
- Alarms
- Dashboards
- Log Insights queries

ဒီ project မှာ CloudWatch ကို ဒီလိုသုံးနိုင်တယ်။

EC2 monitoring:

- CPU utilization
- Status check failed
- Disk usage, memory usage
- Nginx/PHP-FPM logs

RDS monitoring:

- CPU utilization
- Free storage space
- Database connections
- Read/write latency

WAF monitoring:

- Allowed requests
- Blocked requests
- Counted requests
- Rule-level metric
- WAF full logs

Production မှာ CloudWatch Agent install လုပ်ပြီး `/var/log/nginx/access.log`, `/var/log/nginx/error.log`, system logs တွေကို CloudWatch Logs ထဲပို့တာကောင်းတယ်။

## 8. Route 53

Route 53 ဆိုတာ AWS DNS service ပါ။ Domain name ကို AWS resource တွေနဲ့ချိတ်ဖို့သုံးတယ်။

ဒီ project မှာ Route 53 ကို:

- Domain hosted zone manage
- `example.com` ကို CloudFront/ALB နဲ့ alias ချိတ်
- `www.example.com` record ထည့်
- ACM certificate DNS validation record ထည့်

Alias record ဆိုတာ AWS resource တွေကို DNS record အနေနဲ့ချိတ်တဲ့ feature ပါ။ CloudFront, ALB, S3 website endpoint စတာတွေနဲ့ သုံးနိုင်တယ်။

Example:

```text
example.com -> CloudFront distribution
www.example.com -> CloudFront distribution
```

## 9. ACM

ACM ဆိုတာ AWS Certificate Manager ပါ။ HTTPS အတွက် SSL/TLS certificate ထုတ်ဖို့သုံးတယ်။

CloudFront အတွက် ACM certificate ကို `us-east-1` region မှာထုတ်ရမယ်။ ALB အတွက်တော့ ALB ရှိတဲ့ region မှာထုတ်နိုင်တယ်။

ဒီ project မှာ ACM ကို:

- Domain certificate create
- DNS validation
- CloudFront/ALB HTTPS listener မှာ attach

အသုံးပြုမယ်။

သတိထားရန်:

- Certificate validation မပြီးသေးရင် CloudFront/ALB HTTPS setup မပြီးနိုင်ဘူး။
- DNS record မှန်မှ validation အောင်မယ်။
- Wildcard certificate လိုရင် `*.example.com` ထည့်နိုင်တယ်။

## 10. IAM

IAM ဆိုတာ AWS permission management service ပါ။

ဒီ project မှာ IAM ကို ဒီနေရာတွေမှာသုံးနိုင်တယ်။

Terraform user/role:

- Terraform က AWS resource တွေ create လုပ်ဖို့ permission လိုတယ်။
- Bootcamp မှာ admin permission သုံးရလွယ်ပေမယ့် production မှာ least privilege policy သုံးသင့်တယ်။

EC2 instance role:

- EC2 က S3 media bucket ကို access လုပ်ဖို့ IAM role attach လုပ်နိုင်တယ်။
- AWS credential ကို EC2 file system ထဲ hardcode မလုပ်သင့်ဘူး။

GitHub Actions role:

- CI/CD pipeline က Terraform plan/apply လုပ်ဖို့ AWS permission လိုတယ်။
- Long-lived access key ထက် OIDC role assumption က ပိုကောင်းတယ်။

Best practice:

- Access key ကို Git ထဲမထည့်ပါနဲ့။
- Root account မသုံးပါနဲ့။
- MFA enable လုပ်ပါ။
- Permission ကို လိုအပ်သလောက်သာပေးပါ။

## 11. Security Group vs WAF

Security Group နဲ့ WAF က မတူပါဘူး။

Security Group:

- Network layer firewall
- Port/protocol/IP level control
- EC2, RDS, ALB မှာ attach လုပ်တယ်
- ဥပမာ `22`, `80`, `443`, `3306`

WAF:

- HTTP layer firewall
- URL, header, body, query string, IP reputation စတာတွေ inspect လုပ်တယ်
- SQL injection, bad bot, WordPress attack pattern တွေကို block လုပ်နိုင်တယ်

WordPress setup မှာ နှစ်ခုလုံးလိုတယ်။

Example:

- Security Group က RDS ကို EC2 ကနေပဲ MySQL ဝင်ခွင့်ပေးတယ်။
- WAF က `/wp-login.php` attack, SQLi, malicious request တွေကို block/count လုပ်တယ်။

## 12. Terraform State

Terraform state က AWS မှာ create လုပ်ထားတဲ့ resource တွေနဲ့ local Terraform config ကို map လုပ်တဲ့ file ပါ။

Local state:

- Beginner အတွက်ရလွယ်တယ်။
- Team နဲ့ share လုပ်ဖို့မကောင်းဘူး။
- ပျောက်သွားရင် manage ခက်တယ်။

Remote state:

- S3 bucket ထဲသိမ်းတယ်။
- DynamoDB lock table နဲ့ apply conflict ကိုကာကွယ်တယ်။
- Team workflow အတွက်ပိုကောင်းတယ်။

State file ထဲမှာ sensitive data ပါနိုင်လို့:

- Git ထဲ commit မလုပ်ပါနဲ့။
- S3 encryption enable လုပ်ပါ။
- Bucket access ကိုကန့်သတ်ပါ။

## 13. WordPress Deployment Notes

WordPress ကို AWS ပေါ် deploy လုပ်တဲ့အခါ အဓိကသတိထားရမယ့်အချက်တွေ:

- `wp-config.php` ထဲ DB endpoint မှန်ရမယ်။
- RDS security group က EC2 security group ကို allow လုပ်ရမယ်။
- Nginx PHP-FPM socket path မှန်ရမယ်။
- HTTPS termination ကို CloudFront/ALB မှာလုပ်ရင် forwarded headers ကို WordPress သိအောင် configure လုပ်ရမယ်။
- Upload file size ကို Nginx, PHP, WAF သုံးနေရာလုံးစစ်ရမယ်။
- WordPress admin password ကို strong password ထားရမယ်။
- Plugin/theme update တွေကို regular လုပ်ရမယ်။

## 14. Bootcamp Troubleshooting Checklist

Site မပွင့်ဘူးဆိုရင်:

- EC2 running ဖြစ်လား။
- Security group မှာ port `80` ဖွင့်ထားလား။
- Nginx running ဖြစ်လား: `sudo systemctl status nginx`
- PHP-FPM running ဖြစ်လား: `sudo systemctl status php8.3-fpm`
- Nginx config test အောင်လား: `sudo nginx -t`

Database connect မရရင်:

- RDS endpoint မှန်လား။
- DB username/password မှန်လား။
- RDS security group က EC2 security group ကို `3306` allow လုပ်ထားလား။
- EC2 ကနေ MySQL client နဲ့ test လုပ်ကြည့်ပါ။

WAF block ဖြစ်နေရင်:

- CloudWatch Logs Insights မှာ WAF logs query လုပ်ပါ။
- `terminatingRuleId` ကိုကြည့်ပါ။
- False positive ဖြစ်ရင် rule ကို count mode သို့ override လုပ်ပါ။

Terraform error ဖြစ်ရင်:

- `terraform fmt -recursive`
- `terraform validate`
- `terraform plan`
- AWS credential configured ဖြစ်လားစစ်ပါ။
- Region မှန်လားစစ်ပါ။

## 15. Service Mapping

ဒီ repo ထဲက Terraform module တွေကို AWS service တွေနဲ့ mapping လုပ်ရင်:

| Module | AWS Service | Purpose |
| --- | --- | --- |
| `modules/vpc` | VPC, Subnet, IGW, NAT, Route Table | Network foundation |
| `modules/ec2` | EC2, Security Group, Key Pair | WordPress server |
| `modules/rds` | RDS MySQL, DB Subnet Group, Security Group | WordPress database |
| `modules/s3` | S3 | Media upload or Terraform state |
| `modules/cloudfront` | CloudFront | CDN and HTTPS edge |
| `modules/waf` | AWS WAF, CloudWatch Log Group | Web protection and request logs |
| `modules/cloudwatch` | CloudWatch | Metrics, alarms, dashboard |
| `modules/route53` | Route 53 | DNS records |
| `modules/acm` | ACM | SSL/TLS certificate |

## 16. Final Recap

ဒီ architecture မှာ:

- VPC က network foundation ဖြစ်တယ်။
- EC2 က WordPress application server ဖြစ်တယ်။
- RDS က WordPress database ဖြစ်တယ်။
- S3 က media/static object storage ဖြစ်တယ်။
- CloudFront/ALB က user traffic ကို receive လုပ်ပြီး EC2 ကို forward လုပ်တယ်။
- WAF က malicious web request တွေကို filter လုပ်တယ်။
- CloudWatch က metrics/logs/alarm တွေကို collect လုပ်တယ်။
- Route 53 က domain DNS ကို manage လုပ်တယ်။
- ACM က HTTPS certificate ကို manage လုပ်တယ်။
- Terraform က AWS infrastructure အကုန်လုံးကို code နဲ့ manage လုပ်တယ်။

ဒီ foundation ကိုနားလည်သွားရင် AWS ပေါ်မှာ WordPress တင်တာတင်မကဘဲ real-world web application architecture တော်တော်များများကို build လုပ်နိုင်လာမယ်။
