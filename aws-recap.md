# AWS Services Recap

## VPC - Virtual Private Cloud

AWS account ထဲမှာ ကိုယ်ပိုင် virtual network တစ်ခုဆောက်တာပါ။ real-world network တစ်ခုလိုပဲ IP range, subnets, routing, firewall rules တွေကို ကိုယ်တိုင် define လုပ်နိုင်ပါတယ်။

### CIDR Block

VPC create တဲ့အခါ IP address range ကို CIDR notation နဲ့သတ်မှတ်ရပါတယ်။

```text
10.0.0.0/16  ->  10.0.0.0 to 10.0.255.255  (65,536 IPs)
10.0.1.0/24  ->  10.0.1.0 to 10.0.1.255    (256 IPs)
```

VPC CIDR ကို /16 လောက်ကျယ်ကျယ်ထားပြီး subnet တွေကို /24 လောက် ခွဲသုံးတာ common pattern ပါ။

### Subnets

Subnet ဆိုတာ VPC ထဲမှာ IP range ကိုထပ်ခွဲတာပါ။ Subnet တစ်ခုက Availability Zone (AZ) တစ်ခုနဲ့ bind ဖြစ်ပါတယ်။

**Public Subnet:**
- Internet Gateway route ရှိတဲ့ subnet
- Resources တွေကို public IP ပေးနိုင်တယ်
- ALB, NAT Gateway ထားရာ

**Private Subnet:**
- Internet Gateway route မရှိတဲ့ subnet
- Internet ကနေတိုက်ရိုက်ဝင်လို့မရပါ
- Application server, database ထားရာ

High availability အတွက် subnet တွေကို AZ အနည်းဆုံး ၂ ခုမှာ ဖြန့်ထားသင့်ပါတယ်။

### Internet Gateway (IGW)

VPC နဲ့ internet ကိုချိတ်ဆက်ပေးတဲ့ component ပါ။ Public subnet ရဲ့ route table မှာ `0.0.0.0/0 -> IGW` ရှိမှ internet access ရပါတယ်။

### NAT Gateway

Private subnet ထဲက resources တွေ outbound internet ထွက်နိုင်အောင်လုပ်ပေးတဲ့ component ပါ။ ဥပမာ private EC2 မှာ package update ပြုလုပ်တဲ့အခါ NAT Gateway ကတဆင့် internet ထွက်ပါတယ်။

NAT Gateway ကို public subnet ထဲမှာထားပြီး Elastic IP တစ်ခု assign လုပ်ရပါတယ်။ Internet ကနေ private resources ဆီ inbound access မပေးပါ။

### Route Tables

Route table က traffic ဘယ်ကိုသွားမလဲ သတ်မှတ်တဲ့ rules တွေပါ။

Public route table example:

```text
10.0.0.0/16  ->  local
0.0.0.0/0    ->  Internet Gateway
```

Private route table example:

```text
10.0.0.0/16  ->  local
0.0.0.0/0    ->  NAT Gateway
```

### Availability Zones

AZ ဆိုတာ AWS region ထဲမှာ physically separate ဖြစ်တဲ့ data center cluster တွေပါ။ `ap-southeast-1` region မှာ `1a`, `1b`, `1c` ဆိုပြီး AZ သုံးခုရှိပါတယ်။ Resources တွေကို AZ အများဆီဖြန့်ထားရင် AZ တစ်ခု fail ဖြစ်ရင်လည်း service မပျက်ပါ။

---

## ALB - Application Load Balancer

User request တွေကိုလက်ခံပြီး backend targets ဆီ distribute လုပ်တဲ့ Layer 7 (HTTP/HTTPS) load balancer ပါ။

### Load Balancer Types

AWS မှာ load balancer သုံးမျိုးရှိပါတယ်။

- **ALB** — HTTP/HTTPS, Layer 7, path/header-based routing
- **NLB** — TCP/UDP, Layer 4, ultra-low latency
- **CLB** — legacy, သုံးတာမကောင်းတော့ပါ

Web application တွေအတွက် ALB ကပိုသင့်တော်ပါတယ်။

### Listener

ALB က port တစ်ခုကို listen လုပ်တဲ့ configuration ပါ။

- Port `80` listener — HTTP ကို HTTPS ဆီ redirect လုပ်တာများပါတယ်
- Port `443` listener — HTTPS request လက်ခံပြီး target group ဆီ forward လုပ်တယ်

### Listener Rules

Listener rule က request ကို inspect လုပ်ပြီး ဘယ် target group ဆီ forward မလဲ decide လုပ်တာပါ။

Rule conditions:

- Host header (domain name)
- Path pattern (`/api/*`, `/images/*`)
- HTTP method
- Query string
- Source IP

Rule actions:

- Forward to target group
- Redirect
- Fixed response (return static HTTP response)

### Target Groups

Target group က ALB ကနေ traffic receive မယ့် backends တွေကို group လုပ်ထားတာပါ。

Target types:

- **Instance** — EC2 instance ID
- **IP** — private IP address
- **Lambda** — Lambda function

Health check: ALB က target တွေကို regularly health check လုပ်ပြီး unhealthy target ဆီ traffic မပို့ပါ。

### ALB Access Logs

ALB ကိုဖြတ်သွားတဲ့ request တွေကို S3 မှာ log သိမ်းနိုင်ပါတယ်။ Client IP, request time, response code, latency တွေ ပါပါတယ်။

---

## EC2 - Elastic Compute Cloud

AWS virtual machine ပါ။ CPU, memory, storage, OS ကို ကိုယ်တိုင်ရွေးချယ်ပြီး application run ဖို့သုံးပါတယ်။

### Instance Types

Instance type က CPU, memory, network performance ကိုသတ်မှတ်ပါတယ်။

Naming format: `[family][generation][attribute].[size]`

```text
t3.micro    ->  burstable, 2 vCPU, 1 GB RAM
t3a.small   ->  burstable AMD, 2 vCPU, 2 GB RAM
m6i.large   ->  general purpose, 2 vCPU, 8 GB RAM
c6i.xlarge  ->  compute optimized, 4 vCPU, 8 GB RAM
```

Common families:

- `t` — burstable, dev/small workloads
- `m` — general purpose, balanced
- `c` — compute optimized
- `r` — memory optimized
- `i` — storage optimized

### AMI - Amazon Machine Image

AMI ဆိုတာ OS + pre-installed software ပါတဲ့ server template ပါ。 EC2 instance launch မယ်ဆိုရင် AMI ကနေ create လုပ်ပါတယ်。

- AWS official AMIs (Ubuntu, Amazon Linux, Windows)
- AWS Marketplace AMIs
- Custom AMIs (ကိုယ်တိုင် build ထားတာ)

### EBS - Elastic Block Store

EC2 instance ရဲ့ disk storage ပါ。 Instance stop/start ဖြစ်ရင်လည်း data မပျောက်ပါ (instance store နဲ့မတူပါ)。

EBS volume types:

- `gp3` — general purpose SSD, cost-effective, default
- `gp2` — older general purpose SSD
- `io2` — high performance SSD, database workloads
- `st1` — throughput optimized HDD, big data
- `sc1` — cold HDD, infrequent access

### Instance Metadata

EC2 instance ထဲကနေ instance ရဲ့ info တွေကို metadata endpoint မှာ query လုပ်နိုင်ပါတယ်。

```bash
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/local-ipv4
```

### User Data

EC2 launch တဲ့အခါ bootstrap script run ဖို့ user data field မှာ script ထည့်နိုင်ပါတယ်。 Package install, config setup, service start တွေကို automate လုပ်နိုင်ပါတယ်。

### SSM Session Manager

SSH port `22` မဖွင့်ဘဲ private EC2 ကိုဝင်နိုင်တဲ့ AWS native tool ပါ。 IAM role မှာ `AmazonSSMManagedInstanceCore` policy ရှိရပြီး SSM Agent instance မှာ run နေရပါတယ်。

Benefits:

- No SSH key management လိုပါ
- No port `22` public open မလိုပါ
- Session logs CloudWatch/S3 မှာ audit trail ရှိတယ်
- IAM permission နဲ့ control လုပ်နိုင်တယ်

---

## RDS - Relational Database Service

Managed relational database service ပါ。 MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, Aurora engine တွေ support ပါတယ်。

### RDS vs Self-managed DB

| | RDS | Self-managed (EC2) |
|---|---|---|
| OS patching | AWS | ကိုယ်တိုင် |
| DB engine patching | AWS | ကိုယ်တိုင် |
| Backup | Automated + manual | ကိုယ်တိုင် |
| High availability | Multi-AZ one-click | ကိုယ်တိုင် configure |
| Scaling | Easy | ကိုယ်တိုင် |
| Cost | Higher | Lower |

### DB Instance Classes

```text
db.t4g.micro    ->  burstable, low cost, dev
db.t4g.small    ->  burstable, small workload
db.m6g.large    ->  general purpose, production
db.r6g.large    ->  memory optimized, heavy queries
```

### Storage

- **gp2 / gp3** — general purpose SSD
- **io1 / io2** — provisioned IOPS SSD, high performance
- **magnetic** — legacy, avoid

Storage autoscaling: threshold ထက်ကျော်သွားရင် storage ကိုအလိုအလျောက် scale up လုပ်နိုင်ပါတယ်。

### Multi-AZ

Primary DB ကို synchronously replicate လုပ်ပြီး standby ကို AZ ကွဲ ထားပါတယ်。 Primary fail ဖြစ်ရင် standby ကို automatic failover လုပ်ပါတယ်。 Read traffic မဆောင်တဲ့ pure HA solution ပါ。

### Read Replicas

Read-heavy workload အတွက် DB ကို asynchronously replicate လုပ်ပြီး read traffic ကို replica ဆီ distribute လုပ်နိုင်ပါတယ်。 Write ကတော့ primary ကိုပဲသွားရပါတယ်。 Cross-region read replica လည်းထားနိုင်ပါတယ်。

### Automated Backups

Retention period (1-35 days) သတ်မှတ်ထားရင် AWS က daily backup + transaction logs ကိုသိမ်းပြီး point-in-time restore လုပ်နိုင်ပါတယ်。

### Parameter Groups

DB engine settings တွေကို parameter group မှာ configure လုပ်ပါတယ်。 ဥပမာ `max_connections`, `innodb_buffer_pool_size` စတဲ့ MySQL parameters တွေ。

### Secrets Manager Integration

`manage_master_user_password = true` သုံးရင် RDS master password ကို Secrets Manager မှာ auto-rotate လုပ်ပေးပါတယ်。 Plain text password ကို code/config ထဲမထည့်ဘဲ Secrets Manager API ကတဆင့်ဖတ်ပါတယ်。

---

## IAM - Identity and Access Management

AWS ထဲမှာ who can do what ကိုသတ်မှတ်တဲ့ service ပါ。

### Core Concepts

**Users** — human identity。 console/API access ရှိနိုင်တယ်。

**Groups** — users တွေကို group လုပ်ပြီး policy attach လုပ်တာ。

**Roles** — AWS services (EC2, Lambda) or external identities (SSO, cross-account) အတွက် temporary credentials ပေးတဲ့ identity。 EC2 မှာ access key မထည့်ဘဲ role assign လုပ်တာ best practice ပါ。

**Policies** — JSON document ဖြင့် permissions define လုပ်တာ。

### Policy Types

- **AWS Managed** — AWS ပြင်ဆင်ထားတဲ့ built-in policies (`AmazonS3ReadOnlyAccess`, `AmazonSSMManagedInstanceCore`)
- **Customer Managed** — ကိုယ်တိုင် create လုပ်တဲ့ policies
- **Inline** — specific user/role/group ကိုပဲ directly attach လုပ်တာ

### Policy Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

- **Effect** — Allow or Deny
- **Action** — ဘာလုပ်ခွင့်ပေးမလဲ
- **Resource** — ဘယ် resource ကိုသက်ဆိုင်လဲ (ARN)

### Least Privilege

လိုအပ်တဲ့ permission ကိုပဲပေးပါ。 `*` (wildcard) action or resource ကို production မှာ သုံးတာရှောင်ပါ。

### IAM Roles for EC2

EC2 ကို AWS services (S3, SSM, CloudWatch) နဲ့ interact လုပ်စေချင်ရင် access key မသုံးဘဲ IAM role assign လုပ်ပါ。 Instance metadata ကနေ temporary credentials ကို automatically ရပါတယ်。

---

## AWS WAF - Web Application Firewall

HTTP/HTTPS layer မှာ web attacks တွေကို filter လုပ်တဲ့ service ပါ。 Security group က port/IP ပဲ control လုပ်နိုင်ပေမယ့် WAF က HTTP request content ကိုကြည့်ပြီး decide လုပ်နိုင်ပါတယ်。

### WAF Scope

- **REGIONAL** — ALB, API Gateway, AppSync မှာ attach
- **CLOUDFRONT** — CloudFront distribution မှာ attach (certificate `us-east-1` မှာလိုတယ်)

### Web ACL

WAF ရဲ့ main component ပါ。 Rules list ကိုထဲမှာ sequence အတိုင်း evaluate လုပ်ပါတယ်。 Priority number နည်းလေ ဦးစွာ evaluate လုပ်လေပါ。

### Rule Types

**AWS Managed Rule Groups** (ready-made):

- `AWSManagedRulesCommonRuleSet` — OWASP Top 10 common attacks
- `AWSManagedRulesKnownBadInputsRuleSet` — known malicious patterns
- `AWSManagedRulesSQLiRuleSet` — SQL injection
- `AWSManagedRulesAmazonIpReputationList` — known bad IPs
- `AWSManagedRulesPHPRuleSet` — PHP-specific attacks
- `AWSManagedRulesWordPressRuleSet` — WordPress-specific attacks

**Custom Rules**:

- Rate-based rule — IP တစ်ခုကနေ request limit ကျော်ရင် block
- IP set rule — specific IPs allow/block
- Regex pattern — URI/header pattern match လုပ်ပြီး block

### Rule Actions

- **Allow** — request ကိုဖြတ်သွားခွင့်ပေးတယ်
- **Block** — 403 ပြန်ပြီး request ကို block တယ်
- **Count** — block မလုပ်ဘဲ log/metric မှာ count ပဲလုပ်တယ် (testing phase မှာသုံးတာကောင်းတယ်)
- **CAPTCHA** — challenge ဖြေခိုင်းတယ်

### WAF Logging

WAF logs ကို CloudWatch Logs, S3, Kinesis Data Firehose ဆီ ship လုပ်နိုင်ပါတယ်。

CloudWatch Logs Insights query:

```sql
fields @timestamp, action, httpRequest.clientIp, httpRequest.uri, terminatingRuleId
| sort @timestamp desc
| limit 50
```

Blocked requests only:

```sql
filter action = "BLOCK"
| fields @timestamp, httpRequest.clientIp, httpRequest.uri, terminatingRuleId
| sort @timestamp desc
```

Sensitive headers (authorization, cookie) ကို log မှာ redact လုပ်ထားနိုင်ပါတယ်。

---

## Security Groups

EC2, RDS, ALB တို့ ကို attach လုပ်နိုင်တဲ့ stateful virtual firewall ပါ。

### Stateful

Stateful ဆိုတာ outbound rule မသတ်မှတ်ဘဲ inbound allow လုပ်ထားရင် response traffic က automatically ပြန်ဆင်းပါတယ်。 NACL (stateless) နဲ့မတူပါ。

### Inbound / Outbound Rules

Rule မှာ ပါတဲ့ fields:

- **Type** — HTTP, HTTPS, SSH, Custom TCP...
- **Protocol** — TCP, UDP, ICMP
- **Port range** — 80, 443, 3306, 0-65535
- **Source/Destination** — CIDR or another security group ID

### Security Group Referencing

CIDR range (`0.0.0.0/0`) မသုံးဘဲ security group ID ကို source/destination အဖြစ်သုံးနိုင်ပါတယ်。 ဒါကပိုပြီး precise နဲ့ secure ဖြစ်ပါတယ်。

```text
RDS SG inbound:
  Type: MySQL/Aurora
  Port: 3306
  Source: sg-xxxxxxxx  (EC2 security group)
```

ဆိုလိုတာက EC2 security group attach လုပ်ထားတဲ့ instances တွေကပဲ RDS ဆီဝင်ခွင့်ပြုတာပါ。

### Security Group vs NACL

| | Security Group | NACL |
|---|---|---|
| Level | Instance level | Subnet level |
| Stateful | Yes | No (both directions needed) |
| Allow/Deny | Allow only | Allow and Deny |
| Order | All rules evaluate | Priority order |

---

## CloudWatch

AWS resources တွေရဲ့ metrics, logs, alarms, dashboards ကို centralized ကြည့်ရတဲ့ monitoring service ပါ。

### Metrics

AWS services တွေက metrics တွေကို automatically CloudWatch ဆီ publish ပါတယ်。

Common metrics:

```text
AWS/EC2       CPUUtilization, NetworkIn, NetworkOut, DiskReadOps
AWS/RDS       CPUUtilization, DatabaseConnections, FreeStorageSpace
AWS/ELB/ALB   RequestCount, HTTPCode_ELB_5XX_Count, TargetResponseTime
AWS/WAF       BlockedRequests, AllowedRequests, CountedRequests
```

Custom metrics ကိုလည်း CloudWatch API/agent နဲ့ push လုပ်နိုင်ပါတယ်。

### CloudWatch Agent

EC2 instance ထဲမှာ memory, disk usage, process count စတဲ့ OS-level metrics တွေကို collect ဖို့ CloudWatch Agent install လုပ်ရပါတယ်。 Default EC2 metrics (CPUUtilization) ထဲမှာ memory မပါပါ。

### Alarms

Metric value က threshold ကျော်ရင် alarm state ပြောင်းပြီး action trigger လုပ်ပါတယ်。

Alarm states:

- **OK** — metric က threshold အောက်
- **ALARM** — metric က threshold ကျော်
- **INSUFFICIENT_DATA** — data မရသေးဘူး

Alarm actions:

- SNS topic notification
- EC2 action (reboot, stop, terminate)
- Auto Scaling action

### Logs

Application, service, AWS resource logs တွေကို CloudWatch Logs မှာ centralized collect လုပ်နိုင်ပါတယ်。

Concepts:

- **Log Group** — log stream တွေကို group လုပ်တာ (per service/application)
- **Log Stream** — single source ကနေ log sequence (per instance)
- **Retention** — log ကို ဘယ်နှစ်ရက် keep မလဲ (1 day - never expire)

Log Insights query example:

```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

### Dashboards

Custom dashboard ထဲမှာ metrics နဲ့ logs ကို widget အနေနဲ့ arrange လုပ်ပြီး single view မှာကြည့်နိုင်ပါတယ်。

---

## SNS - Simple Notification Service

Publisher ကနေ subscriber ဆီ message ပို့တဲ့ pub/sub service ပါ。

### Topics

Publisher က topic ဆီ message publish ပါတယ်。 Topic ကို subscribe လုပ်ထားတဲ့ subscribers တွေ message ရပါတယ်。

### Subscription Protocols

- **Email** — email address ဆီ notification
- **Email-JSON** — JSON format email
- **HTTP/HTTPS** — webhook endpoint ဆီ POST
- **SQS** — SQS queue ထဲထည့်တယ်
- **Lambda** — Lambda function trigger
- **SMS** — mobile number ဆီ text message

### Email Confirmation

Email subscription create ပြီးရင် AWS က confirmation email ပို့ပါတယ်。 Link click မပြုလုပ်သေးရင် subscription က `PendingConfirmation` state မှာ ရှိပြီး notification မရပါ。

### Fan-out Pattern

Topic တစ်ခုကနေ subscribers အများကြီးဆီ တပြိုင်နက် message reach ဖြစ်ပါတယ်。 ဥပမာ S3 event တစ်ခုဖြစ်ရင် SNS topic ကနေ Lambda function နဲ့ SQS queue နှစ်ခုလုံးကို တပြိုင်နက် notify လုပ်နိုင်ပါတယ်。

---

## ACM - AWS Certificate Manager

SSL/TLS certificate ကို free issue, manage, renew လုပ်ပေးတဲ့ service ပါ。 ALB, CloudFront, API Gateway တို့မှာ attach လုပ်နိုင်ပါတယ်。

### Certificate Types

- **Public** — internet-facing, free, domain validation လိုတယ်
- **Private** — internal use, Private CA service လိုတယ်

### Validation Methods

**DNS Validation** (recommended):

- Route 53 မှာ CNAME record ထည့်ရတယ်
- Auto-renewal ဖြစ်ပါတယ်

**Email Validation**:

- Domain registrant email ဆီ confirmation email ပို့တယ်
- Renewal မှာ manual confirm လိုနိုင်တယ်

### Region Consideration

ACM certificate က region-specific ပါ。

- **ALB** — ALB ရှိတဲ့ region မှာ certificate ရှိရမယ်
- **CloudFront** — `us-east-1` မှာ certificate ရှိရမယ် (CloudFront က global service ဖြစ်ပေမယ့် us-east-1 ပဲ support တယ်)

### Certificate Renewal

ACM public certificates တွေကို AWS က expiry မတိုင်ခင် auto-renew လုပ်ပေးပါတယ်。 DNS validation သုံးထားရင် manual action မလိုပါ။

---

## Route 53 - DNS Service

AWS ရဲ့ scalable DNS service ပါ。 Domain registration, DNS routing, health checking တွေ support ပါတယ်。

### Record Types

| Type | Purpose | Example |
|---|---|---|
| A | Domain to IPv4 | `example.com -> 1.2.3.4` |
| AAAA | Domain to IPv6 | `example.com -> ::1` |
| CNAME | Domain to domain | `www.example.com -> example.com` |
| Alias | Domain to AWS resource | `example.com -> ALB DNS name` |
| MX | Mail server | Email routing |
| TXT | Text data | Domain verification, SPF |
| NS | Name server | Hosted zone delegation |

### Alias Records

AWS-specific record type ပါ。 CNAME နဲ့မတူဘဲ root domain (`example.com`) မှာသုံးနိုင်ပြီး ALB, CloudFront, S3 static website တွေဆီ point လုပ်နိုင်ပါတယ်。 Alias record ကို Route 53 က free resolve လုပ်ပေးပါတယ်。

### Hosted Zones

Hosted zone ဆိုတာ domain တစ်ခုအတွက် DNS records container ပါ。

- **Public hosted zone** — internet-facing DNS
- **Private hosted zone** — VPC ထဲမှာပဲ resolve ဖြစ်တဲ့ internal DNS

### Routing Policies

- **Simple** — single record, basic routing
- **Weighted** — traffic percentage ခွဲပို့တယ် (A/B testing, gradual migration)
- **Latency** — latency အနည်းဆုံး region ဆီ route လုပ်တယ်
- **Failover** — primary unhealthy ဖြစ်ရင် secondary ဆီ redirect
- **Geolocation** — user location အတိုင်း route လုပ်တယ်
- **Geoproximity** — location + bias weight နဲ့ route
- **Multivalue Answer** — multiple healthy records ပြပြီး client ကရွေးတယ်

### Health Checks

Route 53 က endpoint ကို health check လုပ်နိုင်ပြီး unhealthy ဖြစ်ရင် failover routing trigger လုပ်ပါတယ်。

---

## S3 - Simple Storage Service

Object storage service ပါ。 Files တွေကို bucket ထဲမှာ objects အဖြစ်သိမ်းပါတယ်。 Object size limit က 5 TB ပါ。

### Buckets and Objects

- **Bucket** — globally unique name ရှိတဲ့ container
- **Object** — key (file path) + value (file data) + metadata
- **Key** — object ရဲ့ unique identifier (full path like `images/profile/user123.jpg`)

### Storage Classes

| Class | Use case | Cost |
|---|---|---|
| S3 Standard | Frequent access | High |
| S3 Standard-IA | Infrequent access | Medium |
| S3 One Zone-IA | Infrequent, single AZ | Lower |
| S3 Glacier Instant | Archive, milliseconds retrieval | Low |
| S3 Glacier Flexible | Archive, minutes/hours retrieval | Lower |
| S3 Glacier Deep Archive | Long-term archive, 12hr retrieval | Lowest |
| S3 Intelligent-Tiering | Auto-tier based on access | Medium |

### Versioning

Bucket versioning enable ပြုလုပ်ထားရင် object ကို overwrite/delete ဖြစ်ရင်လည်း previous versions ကိုထိန်းသိမ်းပါတယ်。 Accidental deletion recover ဖြစ်ပါတယ်。

### Access Control

- **Bucket Policy** — JSON policy, cross-account access control
- **ACL** — object/bucket level, legacy (avoid if possible)
- **Block Public Access** — bucket ကို public မဖြစ်အောင် lock ထားတဲ့ setting。 Default enable ဖြစ်ပြီး production မှာ always enable ထားသင့်တယ်

### Encryption

- **SSE-S3** — AWS managed keys, default
- **SSE-KMS** — AWS KMS keys, audit trail ရှိတယ်
- **SSE-C** — customer provided keys
- **Client-side** — upload မတိုင်ခင် client side encrypt

### Static Website Hosting

S3 ကို static website (HTML, CSS, JS) host ဖို့သုံးနိုင်ပါတယ်。 Backend မလိုတဲ့ static sites တွေ (React build, Hugo sites) ကို S3 + CloudFront နဲ့ serve လုပ်တာ common pattern ပါ。

### Lifecycle Policies

Objects တွေကို age or count အပေါ်မူတည်ပြီး auto-transition or auto-delete ဖြစ်အောင် configure လုပ်နိုင်ပါတယ်。

ဥပမာ:

```text
30 days  -> move to Standard-IA
90 days  -> move to Glacier
365 days -> delete
```

### S3 Event Notifications

Object upload, delete event တွေဖြစ်ရင် SNS, SQS, Lambda ဆီ notification trigger လုပ်နိုင်ပါတယ်。

---

## Summary

| Service | Category | Core Purpose |
|---|---|---|
| VPC | Networking | Isolated virtual network, subnet, routing |
| ALB | Networking | HTTP/HTTPS load balancer, HTTPS termination |
| EC2 | Compute | Virtual machine, application runtime |
| RDS | Database | Managed relational DB, automated backups |
| IAM | Security | Identity, permission, role management |
| WAF | Security | HTTP-layer request filtering and blocking |
| Security Group | Security | Stateful instance-level network firewall |
| CloudWatch | Monitoring | Metrics, logs, alarms, dashboards |
| SNS | Messaging | Pub/sub notifications to email/SMS/Lambda/SQS |
| ACM | Security | Free SSL/TLS certificate management |
| Route 53 | Networking | DNS management, health checking, routing policies |
| S3 | Storage | Scalable object storage, static hosting |