
#creating vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.name}-vpc"
  }
} 

#creating public and private subnets
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.vpc.id
    availability_zone = "eu-west-1a"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "${var.name}-public-subnet"
  }
}


#creating private subnets
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.vpc.id
    availability_zone = "eu-west-1a"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "${var.name}-private-subnet"
  }
} 

#creating internet gateway
resource "aws_internet_gateway" "igw" {                
    vpc_id = aws_vpc.vpc .id
    
    tags = {  
        Name = "${var.name}-igw"
    }
    }

    #creating nat gateway
resource "aws_nat_gateway" "example" {                 
    allocation_id = aws_eip.eip.id
 subnet_id     = aws_subnet.public-subnet.id
    depends_on = [aws_internet_gateway.igw]

    tags = {
        Name = "${var.name}-NAT"
    }
}


#creating elastic ip 
resource "aws_eip" "eip" {
    domain   = "vpc"
    tags = {
        Name = "${var.name}-eip"
    }
}


#creating route table for publiic subnet
resource "aws_route_table" "pub-rt" {
      vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

    tags = {
    Name = "${var.name}-pub-rt"
  }
} 

#creating route table for private subnet
resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

    tags = {
    Name = "${var.name}-pri -rt"
  }
}  


# associating public route table with public subnet
resource "aws_route_table_association" "pub-rt-assoc" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.pub-rt.id
}
 

# associating private route table with private subnet
resource "aws_route_table_association" "pri-rt-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.pri-rt.id
}


#creating security group for public subnet


resource "aws_security_group" "sg" {
    name        = "${var.name}-sg"
    description = "Allow all inbound and outbound traffic"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH inbound traffic"
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "Allow http inbound traffic"
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "${var.name}-sg"
    }
}
#creating key pair
resource "aws_key_pair" "key" {
  key_name   = "${var.name}-key2"
  public_key = file ("./set25.pub")
}

#creating ec2 instance 

resource "aws_instance" "webserver" {
  ami           = "ami-01abff0fb51badaf8" #redhat
  instance_type = "t3.micro"
  key_name = aws_key_pair.key.key_name
    subnet_id = aws_subnet.public-subnet.id
vpc_security_group_ids = [aws_security_group.sg.id]
associate_public_ip_address = true
 tags = {
  Name = "${var.name}-webserver"
}
}
