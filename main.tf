provider "aws" {
    region = "ap-southeast-2"
} 

variable "vpc_cidr_block" {default = "10.0.0.0/16"}
variable "subnet_cidr_block" {default = "10.0.10.0/24"}
variable "avail_zone" {default = "ap-southeast-2a"}
variable "env_prefix" {default = "dev"}
variable "my_ip" {default = "211.26.246.72/32"}
variable "instance_type" {default = "t2.micro"}
//variable "public_key_location" {default =}

/*
vpc_cidr_block = "10.0.0.0/16"
subnet_cidr_block = "10.0.10.0/24"
avail_zone = "eu-west-3b"
env_prefix = "dev"
my_ip = "211.26.246.72/32"
instance_type = "t2.micro"
//public_key_location = "/c/Users/ravi.senevirathne/.ssh/server-key.pub"
public_key_location = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9YngnhC5subr0eElN1kRW9pBcJnrJCWOHogfzDUarYQwhgbF/tTuGIdqVKHBekRrand9U6IRxXT9c6DsjspbEGgJuJDd53BIecWfO/y836gCyIZRwAPoK5/r/sBdolgYdJyex+3VGEgmfLhN7ulmDm9oSpcKyVefZGzk8d3/xR3PeC/Vxb0QCyWLrltTNapv9HOYuOsH7XGG2XnOFEhS2CXhIWMYYww9QCn5JweDEOaSCtrPSD6RUVFruDCaEB94//rY3a0gfXSU+IEATQ9WXfrNL6R1FCzAyDpnEZRjqsRtab71+TfJq2p1WNzG+NkSM1kmAQo+d488nEDj0riwFKF9+0VT9s0Xh2VA1q88Czp6BkXyKKO8Bp8TQ90wfCmHf47xHfQkt+mp5twkgPJnwImgl1ZqKH1Ad5B4PiiI6FO1OGadUk5a8LDBUMmmHi1t1veNw68pSuTzylvkQqH7nqyarIaKx4vTaKxjaJHolFZAJcg9nutcTVhWpz7ow0K0= Ravi.Senevirathne@VL000090"
*/

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
      Name: "${var.env_prefix}-subnet-1"
  }
}


resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
      Name: "${var.env_prefix}-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
  tags = {
      Name: "${var.env_prefix}-igw"
  }

}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}


resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.my_ip]
  }

  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids = []
  }

    tags = {
      Name: "${var.env_prefix}-sg"
  }

}
     
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

/*
resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = var.public_key_location
}
*/

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  //key_name = aws_key_pair.ssh-key.key_name

  user_data = <<EOF
                    #!/bin/bash
                    sudo yum update -y && sudo yum install -y docker
                    sudo systemctl start docker
                    sudo usermod -aG docker ec2-user
                    docker run -p 8080:80 nginx 
                EOF

    tags = {
      Name: "${var.env_prefix}-server"
  }

}
