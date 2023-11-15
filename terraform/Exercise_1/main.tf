resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name    =   "THUYDEPTRAI"
    }
}

data "aws_key_pair" "key" {
    key_name = "thuydeptrai"
    include_public_key = true
}    

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.10.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "Private-subnet"
    }
}
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.20.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
      Name = "Public-subnet"
    }
}

resource "aws_instance" "T2" {
    count = "4"
    ami = var.template 
    instance_type   =   "t2.micro"
    key_name = data.aws_key_pair.key.key_name
    subnet_id = aws_subnet.public_subnet.id
    tags = {
      Name = "Udacity T2"
    }
}

resource "aws_instance" "M4" {
    count = "2"
    ami = var.template 
    instance_type   =   "m4.large"
    key_name = data.aws_key_pair.key.key_name
    subnet_id = aws_subnet.public_subnet.id
    tags = {
      Name = "Udacity M4"
    }    
  
}