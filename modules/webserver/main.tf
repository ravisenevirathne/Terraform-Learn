
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  #vpc_id = aws_vpc.myapp-vpc.id
  vpc_id = var.vpc_id

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
    values = [var.image_name]
  }

}



resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  #subnet_id = module.myapp-subnet1.subnet.id
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  #key_name = "ravi2005.training@gmail.com-2023"
  key_name = var.key_name

# connection is shared between file and remote-exec provisioners
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    #private_key = file("./../ravi2005.training@gmail.com-2023.pem")
    private_key = file(var.key_location)
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

    tags = {
      Name: "${var.env_prefix}-server"
  }

}