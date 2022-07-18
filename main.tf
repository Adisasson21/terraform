provider "aws" {
  region = "${var.region}"
}


resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc-cidr}"  # variable of the vpc ip
  instance_tenancy = "default"
  enable_dns_hostnames = true           # any instance we'll create its make a dns name

  tags = {
    Name = "MyVPC"
  }
}


resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "MyIGW"
  }
}


resource "aws_route_table" "public-route-table" {   
  vpc_id =  aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"              
    gateway_id = aws_internet_gateway.internet-gateway.id
     }
  tags = {
    Name = "Public Route Table"
  }
 }


  
#Subnet
# Public Subnet

resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "${var.public-subnet-1-cidr}"
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "${var.public-subnet-2-cidr}"
  tags = {
    Name = "Public Subnet 2"
  }
}


# Private Subnet

resource "aws_subnet" "private-subnet-1" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = "${var.private-subnet-1-cidr}"
  tags      = {
    Name    = "Private Subnet 1"
  }
}


resource "aws_subnet" "private-subnet-2" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = "${var.private-subnet-2-cidr}"
  tags      = {
    Name    = "Private Subnet 2"
  }
}

#Route table Association with Public Subnets

resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
 }


resource "aws_route_table_association" "public-subnet-2-route-table-association" {
  subnet_id = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id

 }


#security group
resource "aws_security_group" "security_group_public_80_443" {
  name        = "SG_public_80_443"
  description = "Port 80 and 443 from all world"
  vpc_id      = aws_vpc.vpc.id
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    description ="worldwide"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    description ="worldwide"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    purpose="Public access for web in world for port 80 and 443"
    Name= "security_group_public_80_443"
  }
}

resource "aws_alb" "Elastic_load_balance" {
  subnets = [aws_subnet.public-subnet-1.id]
  security_groups = [aws_security_group.security_group_public_80_443.id]

  tags = {
    Name = "terraform-elb"
  }
}


resource "aws_alb_target_group" "group" {
  name     = "terraform-example-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  stickiness {
    type = "lb_cookie"
  }

  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/login"
    port = 80
  }
}


resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.Elastic_load_balance.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}


resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = aws_alb.Elastic_load_balance.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy"
  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}


resource "aws_route53_record" "CNAME_record" {
  name = "example.com"
  type = "CNAME"
  zone_id = aws_route53_zone.private.zone_id
  ttl     = "300"
  records = ["CNAME_record.example.com"]
  }


resource "aws_route53_zone" "private" {
  name = "example.com"
  vpc {
   vpc_id = aws_vpc.vpc.id
  }
  tags = {
    Name = "terraform-elb"
  }
}

