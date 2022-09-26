provider "aws" {
  region = "eu-central-1"
}
resource "aws_instance" "zabbix_server" {
  ami           = "ami-0fb24592e48dcc04c"
  instance_type = "t2.micro"
  tags = {
    Name = "Student"
  }
}