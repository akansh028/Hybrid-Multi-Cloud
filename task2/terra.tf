
// asssigning the providers
provider "aws" {
  profile = "akansh"
  region  = "ap-south-1"
}



//creating the security keys
resource "tls_private_key" "myterrakey2" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myterrakey2"
  public_key = "${tls_private_key.myterrakey2.public_key_openssh}"


  depends_on = [
    tls_private_key.myterrakey2
  ]
}

resource "local_file" "key-file" {
  content  = "${tls_private_key.myterrakey2.private_key_pem}"
  filename = "myterrakey2.pem"


  depends_on = [
    tls_private_key.myterrakey2
  ]
}




//creating the security groups 
resource "aws_security_group" "sec_group" {
  name        = "sec_group"
  description = "Allows SSH and HTTP"
  vpc_id      = "vpc-03eb0dc18c7b1a5ca"

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
    Name = "sec_group"
  }
}



// creating subnets in 1a and 1b
resource "aws_subnet" "terra_subnet1a"{
  vpc_id  =  "vpc-03eb0dc18c7b1a5ca"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
 tags = {
   Name = "terra_subnet1a"
  }
}

resource "aws_subnet" "terra_subnet1b" {
  vpc_id  =  "vpc-03eb0dc18c7b1a5ca"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "terra_subnet1b"
  }
}



// creating internet gateway
resource "aws_internet_gateway" "terra_ig" {
  vpc_id = "vpc-03eb0dc18c7b1a5ca"

  tags = {
    Name = "terra_ig"
  }
}



// creating routing table
resource "aws_route_table" "terra_route" {
  vpc_id = "vpc-03eb0dc18c7b1a5ca"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terra_ig.id}"
  }
  tags = {
   Name = "terra_route"
  }
}
resource "aws_route_table_association" "terra_route_a" {
  subnet_id      = aws_subnet.terra_subnet1a.id
  route_table_id = aws_route_table.terra_route.id
}
resource "aws_route_table_association" "terra_route_b" {
  subnet_id      = aws_subnet.terra_subnet1b.id
  route_table_id = aws_route_table.terra_route.id
}



//launching the instance 
resource "aws_instance" "os1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.generated_key.key_name
  security_groups = [ "${aws_security_group.sec_group.id}" ]
  subnet_id = "${aws_subnet.terra_subnet1a.id}"
  tags = {
    Name = "os1"
  }
}

resource "aws_instance" "os2" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.generated_key.key_name
  security_groups = [ "${aws_security_group.sec_group.id}" ]
  subnet_id = "${aws_subnet.terra_subnet1b.id}"
  tags = {
    Name = "os2"
  }
}




//creating efs
resource "aws_efs_file_system" "efs1"{
  creation_token = "efs_file_system"

  tags = {
    Name = "efs_file_system"
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs1.id
  subnet_id       = "${aws_subnet.terra_subnet1a.id}"
  security_groups = ["${aws_security_group.sec_group.id}"]
}

output "myip" {
  value = aws_instance.os1.public_ip
}

resource "null_resource" "nullip" {
  depends_on = [
    aws_efs_mount_target.efs_mount,
  ]



  connection {
    agent    = "false"
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${tls_private_key.myterrakey2.private_key_pem}"
    host     = "${aws_instance.os1.public_ip}"
  }

provisioner "remote-exec"{
   
       inline = [
         
          "sudo yum install httpd php git -y",
	  "sudo systemctl start httpd",
	  "sudo systemctl enable httpd",
          "sudo mkfs.ext4  /dev/xvdf",
          "sudo rm -rf /var/www/html/*",
          "sudo mount  /dev/xvdf  /var/www/html",
          "sudo git clone https://github.com/akansh028/terraform.git  /var/www/html"
         ]

    }
}



//creating the s3 bucket
resource "aws_s3_bucket" "terra_bucket" {
  bucket = "akanshbucket0281998"
  acl    = "public-read"

  versioning {
    enabled = true
  }
  
  tags = {
    Name = "terra_bucket" 
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.terra_bucket.bucket
  key    = "terra_bucket"
  acl = "public-read"
  source="C:/Users/akans/Downloads/akansh.jpg"
  depends_on = [ aws_s3_bucket.terra_bucket ]
  
}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "some comment"
}





//creating the cloudfront distribution
resource "aws_cloudfront_distribution" "terra_cloudfront" {


origin {
    domain_name = aws_s3_bucket.terra_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "terra_bucket"
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD",  "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
forwarded_values {
      query_string = false
cookies {
        forward = "none"
      }
    }
viewer_protocol_policy = "allow-all"
     min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  
  }


# Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

viewer_certificate {
    cloudfront_default_certificate = true
  }

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/akans/Downloads/myterrakey2.pem")
    host     = aws_instance.os1.public_ip
  }
}