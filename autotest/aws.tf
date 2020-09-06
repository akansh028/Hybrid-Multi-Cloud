provider "aws" {
  profile = "akansh"
  region  = "ap-south-1"
}

resource "aws_instance" "os1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "myredhatkey"
  security_groups = [ "launch-wizard-9" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/akans/Downloads/myredhatkey.pem")
    host     = aws_instance.os1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "os1"
  }

}


resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.os1.availability_zone
  size              = 1

  tags = {
    Name = "vol1"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.os1.id
  force_detach = true
}

output "myip" {
  value = aws_instance.os1.public_ip
}

resource "null_resource" "nullip" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.os1.public_ip} > publicip.txt"
  }
}

resource "null_resource" "nullmount" {
  depends_on = [
    aws_volume_attachment.ebs_attach,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/akans/Downloads/myredhatkey.pem")
    host     = aws_instance.os1.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/akansh028/terraform.git  /var/www/html"
    ]
  }
}

resource "null_resource" "nullremote" {
  depends_on = [
    null_resource.nullmount,
  ]

  
  provisioner "local-exec" {
    command = "firefox ${aws_instance.os1.public_ip}"
  }
}