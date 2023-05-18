resource "aws_key_pair" "ssh_key_default" {
  key_name   = var.key-name
  public_key = local.public_ssh_key
}

resource "aws_security_group" "jumphost_sg" {
  name        = "bootcamp-sg-${var.username}"
  description = "Allow only SSH"
  vpc_id      = var.vpc-id

  # Generate dualstack ingress for for the following tcp ports: 22 (ssh), 80 (http), 443 (https)
  # Alternatively, only for port 22
  dynamic "ingress" {
    #for_each = { 1 : 22, 2 : 80, 3 : 443 }
    for_each = { 1 : 22 }
    content {
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      from_port        = ingress.value
      to_port          = ingress.value
    }
  }
}

resource "aws_instance" "jumphost" {
  ami           = var.aws-ami-id
  instance_type = var.jumphost_instance_type
  # Use subnet from common vpc, availability zone a1
  subnet_id                   = var.public-subnet-ids[0]
  associate_public_ip_address = true
  # Use availability zone of the chosen subnets
  availability_zone = var.availability-zones[0]
  key_name          = aws_key_pair.ssh_key_default.key_name
  hibernation       = true

  vpc_security_group_ids = [
    aws_security_group.jumphost_sg.id,
    var.internal-vpc-security-group-id
  ]
  root_block_device {
    delete_on_termination = true
    volume_size           = var.jumphost_disk_size_gb
    volume_type           = "gp3"
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get upgrade && sudo apt-get dist-upgrade -y
    sudo apt-get install -y python3-pip
    snap refresh
    if [ \! -z "${var.instance_initial_apt_packages}" ]; then 
      apt-get install -y ${var.instance_initial_apt_packages}
    fi
    if [ \! -z "${var.instance_initial_snap_packages}" ]; then
      snap install ${var.instance_initial_snap_packages}
    fi
    if [ \! -z "${var.instance_initial_classic_snap_packages}" ]; then
      snap install --classic ${var.instance_initial_snap_packages}
    fi
    python3 -m pip install --user ansible
    sudo hostnamectl set-hostname jumphost

  EOF
  # depends_on = [ aws_security_group.project-iac-sg ]
}
