
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public_az1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet_az1_cidr}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "public az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet_az2_cidr}"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "public az2"
  }
}

resource "aws_subnet" "public_az3" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet_az3_cidr}"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "public az3"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id = "${aws_subnet.public_az1.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_az2" {
  subnet_id = "${aws_subnet.public_az2.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_az3" {
  subnet_id = "${aws_subnet.public_az3.id}"
  route_table_id = "${aws_route_table.public.id}"
}
