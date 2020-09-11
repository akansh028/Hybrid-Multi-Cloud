// creating the aws provider
provider "aws" {  
region  = "ap-south-1"  
profile = "akansh"
}


data "http" "ip" {
  url = "http://ipv4.icanhazip.com"
}




// creating the security group for the RDS
resource "aws_security_group" "terra_sg" {
  name        = "terra_sg"
  description = "Allow 3306 inbound traffic only for the public ip of current machine only"

  ingress {
    description = "3306 from Minikube"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terra_sg"
  }
}



// cretaing RDS database instance
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.30"
  instance_class       = "db.t2.micro"
  name                 = "my_sql_db"
  username             = "akansh028"
  password             = "akansh028"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  publicly_accessible = true
  iam_database_authentication_enabled = true
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  apply_immediately = true

  tags = {
    Name  = "db_instance"
  }
}



// getting dns as a output  
output "dns" {
    value = aws_db_instance.db_instance.address
    }


