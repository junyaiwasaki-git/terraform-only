terraform {
  backend "s3" {
    bucket = "iwasakij-tfstate-bucket" # ← あなたのS3バケット名
    key    = "project3/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

# ===========================
# 最新の Amazon Linux 2023 AMI を取得
# ===========================
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"] # Amazon公式
}

# ===========================
# セキュリティグループ設定
# ===========================
resource "aws_security_group" "web_sg" {
  name        = "CL_iwasaki_sg"
  description = "Security Group with intentional holes"
  vpc_id      = "vpc-0f9e349a1dfd9f1bf"

  # SSH許可（自分の管理用IP）
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["118.237.255.201/32"]
    description = "Allow SSH from admin IP only"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["118.237.255.201/32"]
    description = "Allow Tomcat from admin IP"
  }

  # HTTP許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["118.237.255.201/32"]
    description = "Allow HTTP access from specific IP"
  }

  # SSH許可（他サーバーから）
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.33.219/32"]
    description = "Allow SSH from my server IP"
  }

  # すべてのアウトバウンド通信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# ===========================
# EC2 インスタンス作成
# ===========================
resource "aws_instance" "webap_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = "CL_iwasaki_j"
  subnet_id              = "subnet-0e8be82413630b852"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  monitoring             = true
  ebs_optimized          = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "CL_iwasaki_j_learn_terraform"
  }
}

