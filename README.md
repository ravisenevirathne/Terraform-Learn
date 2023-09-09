# Terraform
Terraform is an Infrastructure as Code (IAC) tool developed by HashiCorp that enables organizations to provision and manage their infrastructure and services in a declarative and automated manner. Main advantages of using Terraform in  DevOps and cloud computing are simplicity, scalability, and versatility.
Terraform simplifies infrastructure provisioning, automates repetitive tasks, and enhances infrastructure versioning and documentation. It helps organizations achieve infrastructure as code, improving efficiency, consistency, and collaboration within development and operations teams.

### Below setup is implementend in this Terraform code

![Alt text](image.png)

#### Two modules have been created
    - subnet  -> subnet, route table, Internet gate, route table association
    - webserver -> Instance, AMI, Security group
#### provisioner has been use to copy script to the remote host and install nginx webserver as docker container

#### Finally nginx webserver should be able access on remote server public ip on port 8080 