provider "aws" {
  region = "us-east-1"
  profile = "akansh.agarwal23@gmail.com"
}

variable "ami_type" {
    default = "t2.micro"
}

resource "aws_instance" "web" {
  ami           = "ami-02354e95b39ca8dec"
  instance_type = var.ami_type

}