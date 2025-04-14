//1. create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "yt-vpc"
  }
}

//2. create subnet
variable "vpc_availability_zones" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.vpc_availability_zones)
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 1)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = {
    Name = "Public-${element(var.vpc_availability_zones, count.index)}"
  }
}

resource "aws_subnet" "frontend_private" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.vpc_availability_zones)
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 10)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = {
    Name = "Frontend-Private-${element(var.vpc_availability_zones, count.index)}"
  }
}

resource "aws_subnet" "backend_private" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.vpc_availability_zones)
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 20)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = {
    Name = "Backend-Private-${element(var.vpc_availability_zones, count.index)}"
  }
}
//3. Internet Gateway
resource "aws_internet_gateway" "igw_vpc" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "YT-Internet Gateway"
  }
}

//4. Route table for public subnet
resource "aws_route_table" "yt_route_table_public_subnet" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc.id
  }
  tags = {
    Name = "Public subnet Route Table"
  }
}


resource "aws_eip" "nat" {
  count = length(var.vpc_availability_zones)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.vpc_availability_zones)
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public_subnet[*].id, count.index)
  tags = {
    Name = "NAT-${element(var.vpc_availability_zones, count.index)}"
  }
  depends_on = [aws_internet_gateway.igw_vpc]
}


//8. Route table for Private subnet
resource "aws_route_table" "private" {
  count  = length(var.vpc_availability_zones)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat[*].id, count.index)
  }
  tags = {
    Name = "Private-RT-${element(var.vpc_availability_zones, count.index)}"
  }
}
resource "aws_route_table_association" "frontend_private" {
  count          = length(var.vpc_availability_zones)
  route_table_id = element(aws_route_table.private[*].id, count.index)
  subnet_id      = element(aws_subnet.frontend_private[*].id, count.index)
}

resource "aws_route_table_association" "backend_private" {
  count          = length(var.vpc_availability_zones)
  route_table_id = element(aws_route_table.private[*].id, count.index)
  subnet_id      = element(aws_subnet.backend_private[*].id, count.index)
}