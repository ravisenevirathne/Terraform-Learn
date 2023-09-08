


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet1" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
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



resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = module.myapp-subnet1.subnet.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = "ravi2005.training@gmail.com-2023"

# connection is shared between file and remote-exec provisioners
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file("./../ravi2005.training@gmail.com-2023.pem")
  }

  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  provisioner "remote-exec" {
    inline = [ 
        "export ENV=dev",
        "mkdir newdirname",
        "sh entry-script-on-ec2.sh"   
     ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip}"
  }

  # user_data = <<EOF
  #                   #!/bin/bash
  #                   sudo yum update -y && sudo yum install -y docker
  #                   sudo systemctl start docker
  #                   sudo usermod -aG docker ec2-user
  #                   docker run -p 8080:80 nginx 
  #               EOF
  # moved to entry-script.sh

    tags = {
      Name: "${var.env_prefix}-server"
  }

}
