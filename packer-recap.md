# Packer — Bagisto AMI Builder (မြန်မာလမ်းညွှန်)

## Packer ဆိုတာဘာလဲ？

**Packer** သည် HashiCorp မှထုတ်လုပ်ထားသော **machine image** တည်ဆောက်ရေး tool တစ်ခုဖြစ်သည်။

Machine image ဆိုသည်မှာ operating system (ဥပမာ Ubuntu) နှင့် ကြိုတင်ထည့်သွင်းထားသော software များပါဝင်သည့် snapshot တစ်ခုဖြစ်သည်။ AWS မှာဆိုရင် ၎င်းကို **AMI (Amazon Machine Image)** ဟုခေါ်သည်။

Packer သည် platform အမျိုးမျိုးအတွက် image များကို တစ်ပြိုင်နက်တည်းတည်ဆောက်နိုင်သည် — AWS, GCP, Azure, VMware, Docker စသည်တို့ဖြစ်သည်။

---

## Packer ဘယ်လိုအလုပ်လုပ်လဲ？

Packer ၏အလုပ်လုပ်ပုံကို အဆင့် ၃ ဆင့်ခွဲကြည့်နိုင်သည်။

```
  source (base image)
        │
        ▼
  provisioner (software များထည့်သွင်းခြင်း)
        │
        ▼
  output (golden image)
```

### ၁။ Source
- Base image တစ်ခုကို သတ်မှတ်သည်။ ဥပမာ — Ubuntu 24.04 LTS AMI
- ဤ image သည် စတင်ရန် အခြေခံအလွတ် OS ဖြစ်သည်။

### ၂။ Provision
- Packer သည် temporary EC2 instance တစ်ခုကို launch လုပ်သည်။
- ထို instance ပေါ်တွင် script များဖြင့် software များ ထည့်သွင်းသည် (Nginx, PHP, MySQL client, စသည်)။
- ၎င်းကို **provisioning** ဟုခေါ်သည်။

### ၃။ Output (Artifact)
- Provisioning ပြီးသည်နှင့် Packer သည် instance မှ snapshot (AMI) ကိုဖန်တီးသည်။
- ထို့နောက် temporary instance ကို terminate လုပ်သည်။
- ကျန်ရစ်သော AMI သည် **golden image** ဖြစ်သည် — နောင်တွင် EC2 instance အသစ်များအတွက် အသုံးပြုနိုင်သည်။

---

## ဘာကြောင့် Packer ကိုသုံးသင့်သလဲ？

| အကြောင်းရင်း | ရှင်းလင်းချက် |
|---|---|
| **တူညီမှု (Consistency)** | Image တိုင်းသည် တူညီသော configuration ရှိသည်။ "မနေ့ကအလုပ်လုပ်တာ ဒီနေ့ဘာလို့မလုပ်တာလဲ" ဆိုတဲ့ပြဿနာမရှိတော့ပါ။ |
| **အလိုအလျောက် (Automation)** | Image တည်ဆောက်ခြင်းကို manual လုပ်စရာမလိုတော့ပါ။ `packer build` တစ်ချက်နှိပ်ရုံဖြင့်ရသည်။ |
| **မြန်ဆန်ခြင်း (Speed)** | Golden image ရှိပါက EC2 instance အသစ်တွင် software များပြန်ထည့်စရာမလိုတော့ပါ။ Instance စတင်သည်နှင့် ready ဖြစ်နေသည်။ |
| **Multi-Platform** | တစ်ကြောင်းတည်းသော Packer code ဖြင့် AWS, GCP, Azure, Docker အားလုံးအတွက် image တစ်ပြိုင်နက်တည်းဆောက်နိုင်သည်။ |
| **Version Control** | Packer ဖိုင်များသည် code ဖြစ်သည် — Git ဖြင့် manage လုပ်နိုင်သည်။ |

---

## Code Flow ရှင်းလင်းချက်

ဤ repository ရှိ Packer code သည် **Bagisto golden AMI** တစ်ခုကိုတည်ဆောက်သည်။
( Bagisto အတွက် Nginx + PHP + MySQL + Redis stack)

### File Structure

```
packer/
├── versions.pkr.hcl      # Packer version & plugin သတ်မှတ်ချက်များ
├── variables.pkr.hcl     # Variable များ (region, instance type, etc.)
├── base-ami.pkr.hcl      # Source + Build block (အဓိက Packer code)
└── scripts/
    └── run.sh            # Software များထည့်သွင်းရန် shell script
```

### Flow အသေးစိတ်

```
  ════════════════════════════════════════════════════════════════
  1. versions.pkr.hcl
  ════════════════════════════════════════════════════════════════
     Packer အတွက် plugin များသတ်မှတ်သည်။
     ➜ amazon plugin (AWS အတွက်) ကိုသုံးမည်။
     ➜ version >= 1.3.0 လိုအပ်သည်။

  ════════════════════════════════════════════════════════════════
  2. variables.pkr.hcl
  ════════════════════════════════════════════════════════════════
     Variable များသတ်မှတ်သည် — ၎င်းတို့မှာ
     ➜ aws_region       : ap-southeast-1 (Singapore)
     ➜ instance_type    : t3a.micro
     ➜ source_ami_name  : ubuntu-noble-24.04-amd64-server-*
     ➜ php_version      : 8.3
     ➜ ... စသည်တို့ဖြစ်သည်။

  ════════════════════════════════════════════════════════════════
  3. base-ami.pkr.hcl
  ════════════════════════════════════════════════════════════════
     အဓိက Packer configuration ဖြစ်သည်။

     (က) locals block
         build_timestamp ကိုဖန်တီးသည် — AMI name တွင်
         ထည့်သွင်းရန်အတွက်ဖြစ်သည်။
         ဥပမာ: 20260526153000

     (ခ) source "amazon-ebs" "ubuntu"
         AWS EC2 ပေါ်တွင် AMI တည်ဆောက်မည်ဟုသတ်မှတ်သည်။
         ➜ region, instance type, ssh username သတ်မှတ်သည်။
         ➜ source_ami_filter ဖြင့် အသစ်ဆုံး Ubuntu 24.04 AMI ကိုရှာသည်။
         ➜ AMI name ကို "devops-bootcamp-bagisto-<timestamp>" ဟုသတ်မှတ်သည်။
         ➜ Tags များထည့်သည် (Name, ImageRole, Project, Provisioner)။

     (ဂ) build block
         Image တည်ဆောက်ပုံအဆင့်ဆင့်ကိုသတ်မှတ်သည်။
         ➜ source ကိုရွေးချယ်သည် (အထက်ပါ source)
         ➜ provisioner "shell" ဖြင့် run.sh ကို run သည်။
         ➜ PHP_VERSION နှင့် AWS_REGION ကို env var အနေဖြင့်ပေးပို့သည်။

  ════════════════════════════════════════════════════════════════
  4. scripts/run.sh
  ════════════════════════════════════════════════════════════════
     Instance ပေါ်တွင် run မည့် shell script ဖြစ်သည်။
     ၎င်းသည် အောက်ပါအဆင့်များကိုလုပ်ဆောင်သည်။

     ➜ System update (apt-get update && upgrade)
     ➜ PHP repository ထည့်သွင်းခြင်း (sury.org PPA)
     ➜ Package များထည့်သွင်းခြင်း:
         • Nginx (web server)
         • PHP 8.3 + extensions (fpm, cli, mysql, gd, etc.)
         • MySQL client, Redis CLI
         • Composer, AWS CLI v2
         • CodeDeploy agent
     ➜ Services များ enable လုပ်ခြင်း (nginx, php-fpm, codedeploy-agent)
     ➜ PHP-FPM pool ကို configure လုပ်ခြင်း
     ➜ App directory (/var/www/html/bagisto) ဖန်တီးခြင်း
     ➜ Services များ restart လုပ်ခြင်း
     ➜ Installation များကို verify လုပ်ခြင်း

  ════════════════════════════════════════════════════════════════
  5. Result
  ════════════════════════════════════════════════════════════════
     Packer သည် golden AMI တစ်ခုကိုထုတ်ပေးသည်။
     ၎င်း AMI ကိုအသုံးပြု၍ EC2 instance အသစ်များကို
     ချက်ချင်း Bagisto stack အဆင်သင့်ဖြင့် launch လုပ်နိုင်သည်။
```

### Command Flow (အသုံးပြုပုံ)

```bash
# ၁။ Plugin များ download လုပ်ရန်
packer init .

# ၂။ Configuration မှန်မမှန်စစ်ဆေးရန်
packer validate .

# ၃။ AMI တည်ဆောက်ရန်
packer build .
```

---

## အချုပ်အားဖြင့်

Packer သည် **infrastructure as code** ၏ အရေးပါသော အစိတ်အပိုင်းတစ်ခုဖြစ်သည်။
၎င်းသည် server configuration များကို စံချိန်မီစေပြီး၊ manual setup များကြောင့်ဖြစ်သော အမှားများကိုလျှော့ချပေးကာ
အလိုအလျောက် image တည်ဆောက်ခြင်းကိုဆောင်ရွက်ပေးသည်။
