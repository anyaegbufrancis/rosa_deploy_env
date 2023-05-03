
resource "aws_vpc" "rosa_vpc" {
  cidr_block           = local.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${local.vpc_name}"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = local.subnet_count
  vpc_id                  = aws_vpc.rosa_vpc.id
  cidr_block              = cidrsubnet("${local.vpc_cidr_block}", "${local.newbits}", "${count.index}")
  availability_zone       = var.priv_subnet_azs[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.env}-private-subnet-${var.priv_subnet_azs[count.index]}"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = local.subnet_count
  vpc_id                  = aws_vpc.rosa_vpc.id
  cidr_block              = cidrsubnet("${local.vpc_cidr_block}", "${local.newbits}", "${count.index + length(var.priv_subnet_azs)}")
  availability_zone       = var.priv_subnet_azs[count.index]
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.env}-public-subnet-${var.priv_subnet_azs[count.index]}"
  }
}

resource "aws_internet_gateway" "rosa_vpc_igw" {
  vpc_id = aws_vpc.rosa_vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_eip" "rosa_eip" {
  vpc = true
  tags = {
    Name = "${var.env}_eip"
  }
  depends_on = [
    aws_internet_gateway.rosa_vpc_igw
  ]
}

resource "aws_nat_gateway" "rosa_nat_gw" {
  allocation_id = aws_eip.rosa_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.env}-nat_gw"
  }
}


resource "aws_route_table" "rosa_public_subnet_to_igw_rtb" {
  vpc_id = aws_vpc.rosa_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rosa_vpc_igw.id
  }
  tags = {
    Name = "${var.env}-public_subnets->rosa_igw-rtb"
  }
}

resource "aws_route_table_association" "associate_1" {
  count          = local.subnet_count
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.rosa_public_subnet_to_igw_rtb.id
}

resource "aws_route_table" "rosa_private_subnet_to_ngw_rtb" {
  vpc_id = aws_vpc.rosa_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rosa_nat_gw.id
  }
  tags = {
    Name = "${var.env}-private_subnets->nat_gw"
  }
}

resource "aws_route_table_association" "associate_2" {
  count          = local.subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.rosa_private_subnet_to_ngw_rtb.id
}

resource "aws_security_group" "rosa_vpc_ec2_sg" {
  name        = "jump-server"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.rosa_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ec2_inbound_network
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-${var.ec2_instance_name}-sg"
  }
}

resource "aws_key_pair" "key-pem" {
  key_name = "key-pem"
  public_key = data.local_file.ssh_key_pub.content
}
resource "aws_instance" "deployment_svr" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  key_name                    = "key-pem"
  subnet_id                   = aws_subnet.public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.rosa_vpc_ec2_sg.id]
  tags = {
    Name = "${var.env}-${var.ec2_instance_name}"
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = data.local_file.ssh_key_priv.content
  }

  provisioner "file" {
   source      = "./install/install.sh"
   destination = "/home/ec2-user/install.sh"
 }

  provisioner "remote-exec" {

    inline = [
        "chmod +x ./install.sh",
        "./install.sh"
    ]

  }
}



