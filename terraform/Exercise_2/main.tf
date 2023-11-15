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

resource "aws_security_group" "security" {
    name = "lamda"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description      = "lamda"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress {
        description      = "lamda"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress {
        description      = "lamda"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "lamda"
    }   
}

resource "aws_instance" "T2" {
    count = "4"
    ami = var.template 
    instance_type   =   "t2.micro"
    key_name = data.aws_key_pair.key.key_name
    subnet_id = aws_subnet.public_subnet.id
    tags = {
      Name = "Lambda T2"
    }
}

resource "aws_instance" "M4" {
    count = "2"
    ami = var.template 
    instance_type   =   "m4.large"
    key_name = data.aws_key_pair.key.key_name
    subnet_id = aws_subnet.public_subnet.id
    tags = {
      Name = "Lambda M4"
    }     
}

############Lamda create################


##########create-role-lamda##########

resource "aws_iam_role" "role-lambda" {
    name = "role-lamda"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
  }
EOF
}

#############create-role-monitoring-lamda###############
resource "aws_iam_policy" "policy-lambda" {
    name = "policy-lambda"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
    ]
  }
EOF
}
#####attach-role-policy-for-lamda#####
resource "aws_iam_role_policy_attachment" "policy-role-lamda" {
    role = aws_iam_role.role-lambda.name
    policy_arn = aws_iam_policy.policy-lambda.arn
}
resource "archive_file" "file-python" {
    type = "zip"
#    source_dir = "${path.module}"
    source_file = "${path.module}/lambda.py"
    output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda-tf" {
    function_name = "lambda-tf"
    role = aws_iam_role.role-lambda.arn
    runtime = "python3.11"
    filename = "${path.module}/lambda.zip"
    depends_on = [ aws_iam_role_policy_attachment.policy-role-lamda ]
    handler = "lambda.lambda_handler"
    timeout = 900
    vpc_config {
      subnet_ids =  [aws_subnet.private_subnet.id]
      security_group_ids = [aws_security_group.security.id]
    }
}