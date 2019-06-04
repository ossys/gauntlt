### AWS AMIs ###
# Microsoft Windows Server 2019 Base - ami-02d43577e47e684d9
# Microsoft Windows Server 2016 Base - ami-0bf148826ef491d16
# Microsoft Windows Server 2012 R2 - ami-066663db63b3aa675
# Red Hat Enterprise Linux (RHEL) 7.2 (HVM) - ami-2051294a
# CentOS 7 (x86_64) - With Updates HVM - ami-02eac2c0129f6376b
# CentOS 6 (x86_64) - With Updates HVM - ami-014b38e758721be30
# Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-0a313d6098716f372
# Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-0565af6e282977273
# SUSE Linux Enterprise Server 12 SP4 (HVM), SSD Volume Type - ami-0c55353c85ac52c96
# SUSE Linux Enterprise Server 15 (HVM), SSD Volume Type - ami-06ea7729e394412c8

### Links ###
# Subnets - https://hackernoon.com/manage-aws-vpc-as-infrastructure-as-code-with-terraform-55f2bdb3de2a
# Terraform & Ansible - https://medium.com/@mitesh_shamra/deploying-website-on-aws-using-terraform-and-ansible-f0251ae71f42

provider "aws" {
  region     = "us-east-1"
}

### VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "nwic-vpc"
  }
}

### Subnets
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "Master Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags {
    Name = "Victim Subnet"
  }
}

### Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "VPC IGW"
  }
}

### Route Table
resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

resource "aws_route_table_association" "public-rt" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

### Security Groups
resource "aws_security_group" "niwc-master" {
  name = "niwc-master"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.default.id}"

  tags {
    Name = "Web Server SG"
  }
}

resource "aws_security_group" "niwc-victim"{
  name = "niwc-victim"
  description = "Allow traffic from public subnet"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  tags {
    Name = "DB SG"
  }
}

### Keypair
resource "aws_key_pair" "niwc-cyber" {
  key_name = "niwc-cyber"
  public_key = "${file("./id_rsa.pub")}"
}

### Master Instance ###
resource "aws_instance" "master" {
  ami           = "ami-2051294a"
  instance_type = "t2.large"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.niwc-master.id}"]
  associate_public_ip_address = true

  tags {
    Name = "Master"
  }
}

### Victim Instances ###
resource "aws_instance" "windows_2019" {
  ami           = "ami-02d43577e47e684d9"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "Windows 2019"
  }
}

resource "aws_instance" "windows_2016" {
  ami           = "ami-0bf148826ef491d16"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "Windows 2016"
  }
}

resource "aws_instance" "windows_2012" {
  ami           = "ami-066663db63b3aa675"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "Windows 2012"
  }
}

resource "aws_instance" "rhel_72" {
  ami           = "ami-2051294a"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "RHEL 7.2"
  }
}

resource "aws_instance" "centos_7" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "CentOS 7"
  }
}

resource "aws_instance" "centos_6" {
  ami           = "ami-014b38e758721be30"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "CentOS 6"
  }
}

resource "aws_instance" "ubuntu_18" {
  ami           = "ami-0a313d6098716f372"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "Ubuntu 18"
  }
}

resource "aws_instance" "ubuntu_16" {
  ami           = "ami-0565af6e282977273"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "Ubuntu 16"
  }
}

resource "aws_instance" "suse_15" {
  ami           = "ami-06ea7729e394412c8"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.niwc-cyber.id}"
  subnet_id = "${aws_subnet.private.id}"

  tags {
    Name = "SUSE 15"
  }
}

resource "null_resource" "ansible-provision" {
  depends_on = ["aws_instance.master"]

  ##Create Masters Inventory
  provisioner "local-exec" {
    command =  "echo \"[master]\" > ../ansible/inventories/iv1"
  }
  provisioner "local-exec" {
    command =  "echo \"\n${format("%s ansible_ssh_host=%s", aws_instance.master.tags.Name, aws_instance.master.public_ip)}\" >> ansible/inventories/iv&"
  }
}