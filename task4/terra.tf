
// asssigning the providers
provider "aws" {
  profile = "akansh"
  region  = "ap-south-1"
}



//creating the security keys
resource "tls_private_key" "myterrakey4" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myterrakey4"
  public_key = "${tls_private_key.myterrakey4.public_key_openssh}"


  depends_on = [
    tls_private_key.myterrakey4
  ]
}

resource "local_file" "key-file" {
  content  = "${tls_private_key.myterrakey4.private_key_pem}"
  filename = "myterrakey4.pem"


  depends_on = [
    tls_private_key.myterrakey4
  ]
}



// creating VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "terra_vpc"
  }
}




// creating the security groups for wordpress
// Public security group
resource "aws_security_group" "sec_grp_wp" {
  name        = "sec_grp_wp"
  description = "Allows SSH and HTTP for Public"
  vpc_id      = aws_vpc.terra_vpc.id
  depends_on  = [ aws_vpc.terra_vpc ]

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec_grp_wp"
  }
}

// creating the security groups for mysql
// Public security group
resource "aws_security_group" "sec_grp_mysql" {
  name        = "sec_grp_mysql"
  description = "Allows data for Private database"
  vpc_id      = aws_vpc.terra_vpc.id
  depends_on  = [ aws_vpc.terra_vpc ]

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.sec_grp_wp.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec_grp_mysql"
  }
}



// creating subnets in 1a and 1b
resource "aws_subnet" "terra_subnet1a"{
  vpc_id  =  aws_vpc.terra_vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
 tags = {
   Name = "terra_subnet1a"
  }
}

resource "aws_subnet" "terra_subnet1b" {
  vpc_id  =  aws_vpc.terra_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "terra_subnet1b"
  }
}



// creating internet gateway
resource "aws_internet_gateway" "terra_ig" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_ig"
  }
}



// creating routing table Public
resource "aws_route_table" "terra_route1a" {
  vpc_id = aws_vpc.terra_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terra_ig.id}"
  }
  tags = {
   Name = "terra_route1a"
  }
}
resource "aws_route_table_association" "terra_route_a" {
  subnet_id      = aws_subnet.terra_subnet1a.id
  route_table_id = aws_route_table.terra_route1a.id
}



// creating EIP
resource "aws_eip" "terra_eip" {
  vpc = true
}

// creating NAT Gateway
resource "aws_nat_gateway" "terra_nat" {
  allocation_id = "${aws_eip.terra_eip.id}"
  subnet_id     = "${aws_subnet.terra_subnet1a.id}"

  tags = {
    Name = "terra_nat"
  }
}


// creating routing table NAT
resource "aws_route_table" "terra_route1b" {
  vpc_id = aws_vpc.terra_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.terra_nat.id}"
  }
  tags = {
   Name = "terra_route1b"
  }
}
resource "aws_route_table_association" "terra_route_b" {
  subnet_id      = aws_subnet.terra_subnet1b.id
  route_table_id = aws_route_table.terra_route1b.id
}





//launching the instance for wordpress
resource "aws_instance" "wp_os" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name = aws_key_pair.generated_key.key_name
  security_groups = [ "${aws_security_group.sec_grp_wp.id}" ]
  subnet_id = "${aws_subnet.terra_subnet1a.id}"
  vpc_security_group_ids = [ aws_security_group.sec_grp_wp.id ]
  tags = {
    Name = "wp_os"
  }
}

// launching instance for database
resource "aws_instance" "mysql_os" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.generated_key.key_name
  security_groups = [ "${aws_security_group.sec_grp_mysql.id}" ]
  subnet_id = "${aws_subnet.terra_subnet1b.id}"
  vpc_security_group_ids = [ aws_security_group.sec_grp_mysql.id ]
  tags = {
    Name = "mysql_os"
  }
}




resource "null_resource" "nulllocal"  {
  depends_on = [
    aws_instance.wp_os ,
    aws_instance.mysql_os ,
  ]

  provisioner "local-exec" {
    command = "start firefox  ${aws_instance.wp_os.public_ip}"
  }
}