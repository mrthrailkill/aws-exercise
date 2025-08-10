provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "frontend" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "VPC01"
  }
}

# TODO: consider making this a separate security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.frontend.id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.frontend.id
  
  cidr_block = "10.0.0.0/24"
  #TODO: determine whether this is necessary
  map_public_ip_on_launch = true

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.frontend.id
  
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.frontend.id

  tags = {
    Name = "gw"
  }
}

resource "aws_default_route_table" "frontend" {
  default_route_table_id = aws_vpc.frontend.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "VPC01 frontend"
  }
}

resource "aws_eip" "natgw" {
  public_ipv4_pool = "amazon"
}

resource "aws_nat_gateway" "g" {
  allocation_id = aws_eip.natgw.id
  subnet_id = aws_subnet.public.id
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_key_pair" "bastion" {
  key_name = "bastion"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCADQ6NXTmKK2Er7okHUFW32ZL6zcmWgd5spU/HUkiu"
}

resource "aws_eip" "bastion" {
  public_ipv4_pool = "amazon"
  instance = aws_instance.bastion.id
}

resource "aws_instance" "bastion" {
  # TODO: change to image lookup
  ami           = "ami-0ca5fc5cc5d61441f"
  instance_type = "t3.micro"
  key_name = aws_key_pair.bastion.key_name
  subnet_id = aws_subnet.public.id

  # TODO: set vpc_security_group_ids

  metadata_options {
    # IMDSv2:
    # https://aws.amazon.com/blogs/security/get-the-full-benefits-of-imdsv2-and-disable-imdsv1-across-your-aws-infrastructure/
    http_tokens = "required"
  }

  tags = {
    Name = "VPC01 Bastion"
  }
}

resource "aws_vpc" "backend" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "VPC02"
  }
}
