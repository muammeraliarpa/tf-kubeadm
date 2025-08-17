terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "kubeadm-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "kubeadm-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = { Name = "kubeadm-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "kubeadm-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "k8s_sg" {
  name        = "kubeadm-sg"
  description = "Kubernetes SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    description = "Kube API 6443"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
  }

  ingress {
    description      = "Cluster intra TCP"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    self             = true
  }

  ingress {
    description      = "Cluster intra UDP"
    from_port        = 0
    to_port          = 65535
    protocol         = "udp"
    self             = true
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "kubeadm-sg" }
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_public_key_path)
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Master ---
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.master_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

# --- Workers ---
resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-worker-${count.index}"
    Role = "worker"
  }
}

