#!/bin/bash
# Provisions the AMI with Bagisto dependencies.
# Runs inside a temporary EC2 instance during Packer build.
set -euo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"          # AWS Region (Packer က env var နဲ့ထည့်ပေးတယ်၊ မပါရင် ap-southeast-1)
PHP_VERSION="${PHP_VERSION:-8.3}"               # PHP ဗားရှင်း (Packer က env var နဲ့ထည့်ပေးတယ်၊ မပါရင် 8.3)
APP_DIR="/var/www/html/bagisto"                  # Bagisto app တည်မည့် folder လမ်းကြောင်း

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }  # log ထုတ်ရန် helper function (date + message)

# =================== System Update ============================
log "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# =================== PHP Repository ===========================
log "Adding sury.org PHP repository..."
sudo apt-get install -y ca-certificates curl lsb-release
curl -fsSL https://packages.sury.org/php/apt.gpg \
  | sudo tee /usr/share/keyrings/deb.sury.org-php.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] \
  https://packages.sury.org/php/ $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/php-sury.list > /dev/null
sudo apt-get update -y

# =================== Install Packages =========================
log "Installing packages..."
sudo apt-get install -y \
  nginx \
  php${PHP_VERSION} \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-common \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-zip \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-opcache \
  php${PHP_VERSION}-readline \
  default-mysql-client \
  redis-tools \
  git curl wget unzip zip \
  jq rsync imagemagick ruby-full \
  software-properties-common

# =================== Enable Services ==========================
log "Enabling services..."
sudo systemctl enable nginx
sudo systemctl enable php${PHP_VERSION}-fpm

# =================== Composer =================================
log "Installing Composer..."
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f /tmp/composer-setup.php

# =================== AWS CLI v2 ===============================
log "Installing AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

# =================== CodeDeploy Agent =========================
log "Installing CodeDeploy agent..."
cd /home/ubuntu
wget -q "https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install" -O install
chmod +x ./install
sudo ./install auto
rm -f ./install
sudo systemctl enable codedeploy-agent
sudo systemctl start codedeploy-agent

# =================== App Directory ============================
log "Creating app directory..."
sudo mkdir -p ${APP_DIR}
sudo chown -R www-data:www-data ${APP_DIR}

# =================== Restart Services =========================
log "Restarting services..."
sudo systemctl restart php${PHP_VERSION}-fpm
sudo systemctl restart nginx

# =================== Verify ===================================
log "=== Verifying installations ==="
nginx -v
php -v
composer --version
mysql --version
redis-cli --version
aws --version
sudo systemctl status codedeploy-agent --no-pager

log "=== Setup complete ==="
