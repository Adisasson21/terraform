provider "aws" {
  region = "${var.region}"
}
נציין איפה נרצה שהתשתית שלנו תפעל

resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc-cidr}"  # variable of the vpc ip
  instance_tenancy = "default"
  enable_dns_hostnames = true           # any instance we'll create its make a dns name

  tags = {
    Name = "MyVPC"
  }
}

הענן הפרטי מאפשר לנו לבודד את הענן בין לקוחות שונים

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "MyIGW"
  }
}


# Route table for Public Subnets
ניתוב המידע,  היא בעצם אחראית לאן תופנה תעבורת הרשת מהתת רשת
הניתוב הזה הוא קישור של המידע המועבר מהנתב לרשת החיצונית (האינטרנט)
  
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
היא חלק מרשת גדולה, היא נועדה לעזור לזרימת תעבורת הרשת להיות יותר יעילה
  
# Public Subnet
היא רשת משנה שמאפשרת למופעים ברשת להיות נגישים לאינטרנט ואנשים יש גישה לאותם מופעים דרך האינטרנט
נבחר ברשת משנה כזאת כאשר מופעים חייבים להיות בתקשורת עם האינטרנט לדוגמא: בלוג

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
רשת משנה פרטים נועדה כדי לאבטח מופעי קצה שאינם צריכים להיות מחוברים לאינטרנט

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
ניתב המידע מהתת רשת אל הנתב, לנתב אחד יכולים להיות כמה רשתות משנה שמחוברות אליו אבל רשת משנה לא יכולה להיות מחוברת לכמה נתבים שונים
שני הרשתות משנה הציבוריות שיצרתי מחוברת לאותו נתב
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
