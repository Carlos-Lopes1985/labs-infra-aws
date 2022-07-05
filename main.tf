provider "aws" {

  region = "us-east-1"

}


terraform {

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "~> 4.0.0"

    }

  }

  required_version = ">= 1.0"

}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id         = aws_subnet.main.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "default" {
  name        = "default-infra"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

/*====
EC2 

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  key_name                    = "infra-labs"
  depends_on = [ data.aws_ami.ubuntu]
}
======*/

/*====
ECR repository to store our Docker images
======*/
resource "aws_ecr_repository" "openjobs_app" {
  name = "infra-labs-ecr"
}