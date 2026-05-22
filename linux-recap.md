# Linux Recap - DevOps Bootcamp

Linux basics ကို practical view နဲ့ recap လုပ်ထားတဲ့ document ပါ။

## Linux ဆိုတာဘာလဲ

Linux က operating system kernel ဖြစ်ပြီး server world မှာအများကြီးသုံးပါတယ်။ Ubuntu, Debian, Amazon Linux စတာတွေက Linux distribution တွေပါ။

Server ပေါ်မှာ application run မယ်ဆိုရင် Linux basics သိဖို့လိုပါတယ်။ Infrastructure tool တွေက resources ဆောက်ပေးနိုင်ပေမယ့် server ထဲမှာ service တွေ running ဖြစ်နေလား၊ logs မှာ error ရှိလား၊ file permission မှန်လား ဆိုတာတွေကို Linux command နဲ့စစ်ရပါတယ်။

## Terminal and Shell

Terminal က command ရိုက်တဲ့ interface ပါ။ Shell က command ကို interpret လုပ်ပေးတဲ့ program ပါ။ Ubuntu မှာ `bash` ကိုအများဆုံးတွေ့ရပြီး `zsh` သုံးနေရင်လည်း Linux command basics ကအတူတူပါပဲ။

Command syntax အခြေခံ:

```bash
command option argument
```

ဥပမာ:

```bash
ls -la /var/www/html
```

ဒီ command မှာ:

- `ls` က command
- `-la` က options
- `/var/www/html` က argument/path

## Filesystem Basics

Linux filesystem က root path `/` ကနေစပါတယ်။

အရေးကြီးတဲ့ paths:

- `/home/ubuntu`: Ubuntu user ရဲ့ home directory
- `/tmp`: temporary files ထားတဲ့နေရာ
- `/var/www/html`: web root (static files, application files)
- `/etc/nginx`: Nginx configuration files
- `/run/php`: PHP-FPM socket files
- `/var/log`: service logs တွေ
- `/usr/share/keyrings`: APT repository signing keys
- `/etc/apt/sources.list.d`: extra APT repository list files

## Navigation Commands

လက်ရှိ path ကြည့်ရန်:

```bash
pwd
```

Folder ထဲဝင်ရန်:

```bash
cd /etc/nginx
```

အပေါ် folder ပြန်တက်ရန်:

```bash
cd ..
```

Home folder သို့ပြန်ရန်:

```bash
cd ~
```

Files/folders စာရင်းကြည့်ရန်:

```bash
ls
ls -la
```

`ls -la` က hidden files, owner, permission, size, modified time တွေကိုပြပါတယ်။

## Reading Files

File ကို terminal မှာဖတ်ရန်:

```bash
cat /etc/nginx/sites-available/default
```

ရှည်တဲ့ file ကို page by page ဖတ်ရန်:

```bash
less /etc/nginx/nginx.conf
```

File အစပိုင်းပဲကြည့်ရန်:

```bash
head -n 40 /etc/nginx/nginx.conf
```

File နောက်ဆုံးပိုင်းကြည့်ရန်:

```bash
tail -n 40 /var/log/nginx/error.log
```

Log file ကို live follow လုပ်ရန်:

```bash
sudo tail -f /var/log/nginx/error.log
```

## Creating, Copying, Moving Files

Folder create လုပ်ရန်:

```bash
mkdir notes
mkdir -p /tmp/myapp/config
```

File copy လုပ်ရန်:

```bash
cp source.txt destination.txt
```

Folder copy လုပ်ရန်:

```bash
cp -r sourcedir/ /var/www/html/
```

File/folder move or rename လုပ်ရန်:

```bash
mv old-name.txt new-name.txt
```

File delete လုပ်ရန်:

```bash
rm file.txt
```

သတိထားရန်: `rm -rf` က powerful ဖြစ်ပြီး mistake ဖြစ်ရင် files တွေပြန်မရနိုင်ပါ။ Delete မလုပ်ခင် path မှန်တာကို `pwd` နဲ့ `ls` ဖြင့်အရင်စစ်ပါ။

## Searching with grep and rg

Text ရှာချင်ရင် `grep` သို့မဟုတ် `rg` command သုံးနိုင်ပါတယ်။

```bash
grep -r "nginx" /etc
rg "error" /var/log/nginx
```

File name တွေရှာရန်:

```bash
find /etc -name "*.conf"
rg --files /etc/nginx
```

Sensitive files တွေကို မလိုအပ်ဘဲ search/read မလုပ်သင့်ပါ။ `.env`, `.key`, `.pem` files တွေက sensitive ဖြစ်နိုင်ပါတယ်။

## sudo and Root Permission

Linux မှာ normal user နဲ့ root/admin permission မတူပါ။

System-level changes လုပ်မယ်ဆိုရင် `sudo` လိုပါတယ်။

```bash
sudo apt-get update
sudo systemctl restart nginx
sudo cp myapp.conf /etc/nginx/sites-available/default
```

`sudo` သုံးတဲ့အခါ command က system ကိုပြောင်းနိုင်လို့ path နဲ့ command ကိုသေချာစစ်ပါ။

## Package Management with apt

Ubuntu/Debian မှာ package install လုပ်ဖို့ `apt` or `apt-get` သုံးပါတယ်။

Package index update:

```bash
sudo apt-get update
```

Installed packages upgrade:

```bash
sudo apt-get upgrade -y
```

Package install:

```bash
sudo apt-get install -y nginx git curl unzip
```

Common packages:

- `nginx`: web server
- `php8.3-fpm`: PHP application runtime
- `php8.3-mysql`: PHP MySQL extension
- `default-mysql-client`: MySQL command-line client
- `curl`, `wget`: HTTP requests / file download
- `unzip`, `zip`: compressed files handle
- `git`: source control
- `jq`: JSON output parse

## APT Repositories and Signing Keys

တချို့ package တွေက Ubuntu default repository ထဲမပါနိုင်ပါ။ အဲဒီအခါ extra APT repository ထည့်ရပါတယ်။

Signing key download and store:

```bash
wget -O- https://example.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/example-keyring.gpg >/dev/null
```

Repository list file ထည့်ရန်:

```bash
echo "deb [signed-by=/usr/share/keyrings/example-keyring.gpg] https://apt.example.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/example.list
```

Concept အနေနဲ့:

- Signing key က package source ကို trust လုပ်ဖို့သုံးတယ်။
- Source list က package download လုပ်မယ့် repository URL ကိုသတ်မှတ်တယ်။
- Repository အသစ်ထည့်ပြီးရင် `sudo apt update` ထပ် run ရတယ်။

## Users, Groups, and Ownership

Linux file တစ်ခုမှာ owner user နဲ့ owner group ရှိပါတယ်။

ကြည့်ရန်:

```bash
ls -la /var/www/html
```

Example output:

```text
drwxr-xr-x  5 www-data www-data 4096 May 22 10:00 .
```

ဒီမှာ:

- `www-data` ပထမတစ်ခုက owner user
- `www-data` ဒုတိယတစ်ခုက owner group
- `drwxr-xr-x` က permission

File ownership ပြောင်းရန်:

```bash
sudo chown -R www-data:www-data /var/www/html
```

## Permissions

Linux permission မှာ read, write, execute ဆိုပြီးရှိပါတယ်။

Symbol:

- `r`: read
- `w`: write
- `x`: execute

Numeric permission:

- `7`: read + write + execute
- `5`: read + execute
- `4`: read only

Web root အတွက် common setting:

```bash
sudo chmod -R 755 /var/www/html
```

`755` ဆိုတာ:

- Owner: read/write/execute
- Group: read/execute
- Others: read/execute

Script executable ဖြစ်အောင်:

```bash
chmod +x myscript.sh
```

## Processes and Services

Process ဆိုတာ running program ပါ။ Service ဆိုတာ background မှာ run နေတဲ့ managed process လို့နားလည်နိုင်ပါတယ်။

Linux server မှာ services တွေကို `systemctl` နဲ့ manage လုပ်ပါတယ်။

Service start and enable (boot မှာပါ run ဖို့):

```bash
sudo systemctl enable --now nginx
sudo systemctl enable --now php8.3-fpm
```

Status စစ်ရန်:

```bash
systemctl status nginx
systemctl status php8.3-fpm
```

Restart:

```bash
sudo systemctl restart nginx
```

Reload (config ပြောင်းပြီးနောက်):

```bash
sudo systemctl reload nginx
```

`restart` က service ကိုပိတ်ပြီးပြန်ဖွင့်တာပါ။ `reload` က config ပြန်ဖတ်တာဖြစ်ပြီး downtime နည်းနိုင်ပါတယ်။

## Logs with journalctl

Systemd-managed services တွေရဲ့ logs ကို `journalctl` နဲ့ကြည့်နိုင်ပါတယ်။

Service logs ကြည့်ရန်:

```bash
sudo journalctl -u nginx --no-pager -n 100
sudo journalctl -u php8.3-fpm --no-pager -n 100
```

Live follow:

```bash
sudo journalctl -u nginx -f
```

Troubleshooting မှာ service status နဲ့ logs ကိုတွဲကြည့်တာအရေးကြီးပါတယ်။

```bash
systemctl status nginx
sudo journalctl -u nginx --no-pager -n 50
```

## Nginx Basics

Nginx က web server ပါ။ User browser ကလာတဲ့ HTTP request ကိုလက်ခံပြီး static file ပြန်ပေးနိုင်သလို PHP request ကို PHP-FPM ဆီ forward လုပ်နိုင်ပါတယ်။

Config အရေးကြီးတဲ့ parts:

```nginx
listen 80 default_server;
server_name _;
root /var/www/html;
index index.php index.html index.htm;
```

PHP request ကို PHP-FPM ဆီပို့ရန်:

```nginx
location ~ \.php$ {
  fastcgi_pass unix:/run/php/php8.3-fpm.sock;
  fastcgi_index index.php;
  include fastcgi_params;
  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

Health check endpoint:

```nginx
location = /health {
  access_log off;
  add_header Content-Type text/plain;
  return 200 "ok\n";
}
```

Nginx config syntax စစ်ရန်:

```bash
sudo nginx -t
```

Config မှန်ရင် reload:

```bash
sudo systemctl reload nginx
```

## PHP-FPM Basics

PHP application တွေကို Nginx ကိုယ်တိုင် run မပါ။ PHP request ကို PHP-FPM service ဆီပို့ပါတယ်။

PHP version စစ်ရန်:

```bash
php --version
```

Installed PHP modules စစ်ရန်:

```bash
php -m
```

Useful PHP modules:

- `curl`
- `gd`
- `imagick`
- `intl`
- `mbstring`
- `mysql`
- `xml`
- `zip`

## MySQL Client

MySQL client install လုပ်ရန်:

```bash
sudo apt-get install -y default-mysql-client
```

Version စစ်ရန်:

```bash
mysql --version
```

Remote MySQL/RDS endpoint ကို test connect လုပ်ချင်ရင်:

```bash
mysql -h your-db-endpoint -u dbuser -p
```

Password ကို command line ထဲမှာ plain text မရေးသင့်ပါ။ `-p` ကိုပဲပေးပြီး prompt တက်မှရိုက်တာပိုကောင်းပါတယ်။

## Networking Commands

Server IP addresses ကြည့်ရန်:

```bash
ip addr
```

Listening ports ကြည့်ရန်:

```bash
sudo ss -tulpn
```

Port 80 listen ဖြစ်နေလားစစ်ရန်:

```bash
sudo ss -tulpn | grep ':80'
```

Local HTTP test:

```bash
curl -I http://localhost
curl http://localhost/health
```

DNS resolve စစ်ရန်:

```bash
getent hosts example.com
```

Common ports:

- `80`: HTTP
- `443`: HTTPS
- `3306`: MySQL
- `22`: SSH

## Shell Script Basics

`.sh` files တွေက shell scripts ပါ။

Script အစမှာ shebang ထည့်ရန်:

```bash
#!/usr/bin/env bash
```

Common safety settings:

```bash
set -e          # command fail ဖြစ်ရင် script ရပ်သွားမယ်
set -euo pipefail  # stricter version
```

`-e`: command fail ဖြစ်ရင် stop  
`-u`: undefined variable သုံးရင် error  
`-o pipefail`: pipeline ထဲက command fail ဖြစ်ရင် pipeline fail ဖြစ်တယ်

Fail-fast ဖြစ်ဖို့ ဒီ settings တွေကိုနားလည်ထားတာကောင်းပါတယ်။

## Environment Variables

Environment variable က command/script ကို value ပေးတဲ့နည်းတစ်ခုပါ။

Default value နဲ့သတ်မှတ်ရန်:

```bash
PHP_VERSION="${PHP_VERSION:-8.3}"
```

Run တဲ့အခါ override လုပ်နိုင်ပါတယ်:

```bash
PHP_VERSION=8.2 ./install.sh
```

Variable ပြသရန်:

```bash
echo $PHP_VERSION
env | grep PHP
```

## Logs and Troubleshooting Checklist

Nginx config error ဖြစ်ရင်:

```bash
sudo nginx -t
sudo journalctl -u nginx --no-pager -n 50
```

Website 502 ဖြစ်ရင် PHP-FPM ကိုစစ်ပါ:

```bash
systemctl status php8.3-fpm
sudo journalctl -u php8.3-fpm --no-pager -n 50
ls -la /run/php/
```

Website 403 ဖြစ်ရင် permission/root path ကိုစစ်ပါ:

```bash
ls -la /var/www/html
sudo tail -n 50 /var/log/nginx/error.log
```

Website 404 ဖြစ်ရင် Nginx root and application files ကိုစစ်ပါ:

```bash
ls -la /var/www/html/index.php
grep -n "root" /etc/nginx/sites-enabled/default
```

Command not found ဖြစ်ရင် package install ဖြစ်ထားလားစစ်ပါ:

```bash
which nginx
which php
which mysql
```

Disk space ပြည့်နေလားစစ်ရန်:

```bash
df -h
```

Memory usage စစ်ရန်:

```bash
free -h
```

Running processes ကြည့်ရန်:

```bash
ps aux
```

## Safe Linux Habits

- `pwd` နဲ့လက်ရှိ folder အမြဲသိအောင်လုပ်ပါ။
- `sudo` မသုံးခင် command ကိုပြန်ဖတ်ပါ။
- `rm -rf` မသုံးခင် path ကို `ls` နဲ့အရင်စစ်ပါ။
- Secret files မဖတ်/မပြ/မ commit လုပ်ပါနဲ့။
- Config ပြင်ပြီးတိုင်း syntax test လုပ်ပါ။
- Service restart/reload ပြီး status/logs စစ်ပါ။
- Logs ကို error message အတိုင်းဖတ်ပြီး guess မလုပ်ဘဲ အဆင့်လိုက်စစ်ပါ။

## Practice Commands

Server မှာ practice:

```bash
whoami
hostname
ip addr
df -h
free -h
systemctl status nginx
systemctl status php8.3-fpm
sudo nginx -t
curl http://localhost/health
php --version
mysql --version
```

Troubleshooting mindset:

```text
Is the service installed?
Is the service running?
Is the config valid?
Is the port listening?
Can localhost respond?
Do logs show a clear error?
```

## Summary

Linux server ကိုနားလည်ဖို့ packages, services, permissions, configs, logs တွေကိုသိဖို့လိုပါတယ်။

အဓိကမှတ်ထားရန်:

- Web files က `/var/www/html` မှာနေပါတယ်
- Nginx က port `80` မှာ listen ပါတယ်
- PHP က `php-fpm` service ကတစ်ဆင့် run ပါတယ်
- Service problems ကို `systemctl`, `journalctl`, `/var/log`, `curl`, `ss` တို့နဲ့စစ်တယ်
- Secrets and state files ကိုမဖတ်/မ commit လုပ်တာက safety habit ဖြစ်တယ်