provider "aws" {
  region  = "ap-south-1"
  profile = "akansh"
}

variable "key_pair"{
	type = string
	default = "myredhatkey"
}

resource "aws_instance" "terra1" {
  ami           = "ami-0f59936bb535cad5b"
  instance_type = "t2.micro"
  key_name      = var.key_pair
  security_groups = ["launch-wizard-9"]
  tags = {
    Name = "akansh_terra1"
  }
}

resource "aws_instance" "terra2" {
  ami           = "ami-0f59936bb535cad5b"
  instance_type = "t2.micro"
  key_name      = var.key_pair
  security_groups = ["launch-wizard-9"]
  tags = {
    Name = "akansh_terra2"
  }
}

output "key1" {
	value = aws_instance.terra1.key_name
}

output "key2" {
	value = aws_instance.terra2.key_name
}
 
output "myaz1" {
	value = aws_instance.terra1.availability_zone
}

output "myaz2" {
	value = aws_instance.terra2.availability_zone
}

output "attach1"{
	value = aws_ebs_volume.ebs1.id
}

output "attach2"{
	value = aws_ebs_volume.ebs2.id
}


resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.terra1.availability_zone
  size              = 1

  tags = {
    Name = "myebs1"
  }
}

resource "aws_ebs_volume" "ebs2" {
  availability_zone = aws_instance.terra2.availability_zone
  size              = 1

  tags = {
    Name = "myebs2"
  }
}

resource "aws_volume_attachment" "ebs_attach1" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.terra1.id
}

resource "aws_volume_attachment" "ebs_attach2" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs2.id
  instance_id = aws_instance.terra2.id
}

