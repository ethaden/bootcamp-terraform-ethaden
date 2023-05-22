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
    for_each = { 1 : 22, 2: 80, 3: 443 }
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

  tags = {
    Name = "${var.dns-suffix}-jumphost"
    description = "Jupmhost node - Managed by Terraform"
    role = "jumphost"
    sshUser = var.linux-user
    region = var.region
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get upgrade && sudo apt-get dist-upgrade -y
    sudo apt-get install -y python3-pip nginx certbot python3-certbot-nginx
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


resource "aws_eip" "jumphost_eip" {
  instance = aws_instance.jumphost.id
  vpc      = true
}

resource "aws_route53_record" "jumphost-public" {
  zone_id = var.zoneid_public_dns
  name    = "jumphost.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.jumphost_eip.public_ip]
}

data "cloudinit_config" "jumphost_init" {
  gzip          = false
  base64_encode = false
  part {
    #filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content  = <<-EOF
        #cloud-config
        # See documentation for more configuration examples
        # https://cloudinit.readthedocs.io/en/latest/reference/examples.html 

        # Install arbitrary packages
        # https://cloudinit.readthedocs.io/en/latest/reference/examples.html#install-arbitrary-packages
        packages:
        - python3-pip
        - certbot
        - python3-certbot-nginx
        # Run commands on first boot
        # https://cloudinit.readthedocs.io/en/latest/reference/examples.html#run-commands-on-first-boot
        write_files:
        - path: /etc/nginx/sites-enabled/proxy
          content: |
                server {
                  listen 80 default_server;
                  listen [::]:80 default_server;
                  root /var/www/html;
                }
                server {
                  listen 80;
                  listen [::]:80;
                  root /var/www/html;
                  server_name control-center.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name};
                  location / {
                      proxy_pass https://controlcenter-0.${var.username}.${data.aws_route53_zone.private_dns.name}:9021/;
                    proxy_ssl_verify off;
                  }
                }
                server {
                  listen 80;
                  listen [::]:80;
                  root /var/www/html;
                  server_name prometheus.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name};
                  location / {
                      proxy_pass http://prometheus.${var.username}.${data.aws_route53_zone.private_dns.name}:9090/;
                    proxy_ssl_verify off;
                  }
                }
                server {
                  listen 80;
                  listen [::]:80;
                  root /var/www/html;
                  server_name grafana.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name};
                  location / {
                      proxy_pass http://grafana.${var.username}.${data.aws_route53_zone.private_dns.name}:3000/;
                    proxy_ssl_verify off;
                    proxy_set_header Host $http_host;
                  }
                }
        runcmd:
        - sudo hostnamectl set-hostname proxy
        - sudo sed -i 's/#Domains=/Domains=${data.aws_route53_zone.private_dns.name}' /etc/systemd/resolved.conf
        - sudo systemctl daemon-reload
        - sudo systemctl restart systemd-resolved.service
        - sudo sed -i 's/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 128/' /etc/nginx/nginx.conf
        - sudo rm -f /etc/nginx/sites-enabled/default
        - sudo systemctl restart nginx
        - sudo certbot --nginx -d control-center.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name} -d prometheus.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name} -d grafana.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name} --non-interactive --agree-tos -m ${var.username}@confluent.io
        - sudo systemctl restart nginx
    EOF
  }
}

resource "aws_instance" "proxy" {
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
    volume_size           = 25
    volume_type           = "gp3"
    encrypted             = true
  }
  tags = {
    Name = "${var.dns-suffix}-proxy"
    description = "Proxy node - Managed by Terraform"
    role = "proxy"
    sshUser = var.linux-user
    region = var.region
  }

  user_data = data.cloudinit_config.jumphost_init.rendered
}

resource "aws_eip" "proxy_eip" {
  instance = aws_instance.proxy.id
  vpc      = true
}
data "aws_route53_zone" "public_dns" {
  zone_id         = var.zoneid_public_dns
  private_zone = false
}

data "aws_route53_zone" "private_dns" {
  zone_id         = var.hosted-zone-id
  private_zone = true
}


resource "aws_route53_record" "control-center-public" {
  zone_id = var.zoneid_public_dns
  name    = "control-center.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.proxy_eip.public_ip]
}

resource "aws_route53_record" "prometheus-public" {
  zone_id = var.zoneid_public_dns
  name    = "prometheus.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.proxy_eip.public_ip]
}

resource "aws_route53_record" "grafana-public" {
  zone_id = var.zoneid_public_dns
  name    = "grafana.${var.username}.cp-bootcamp.${data.aws_route53_zone.public_dns.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.proxy_eip.public_ip]
}
