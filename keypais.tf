
resource "aws_key_pair" "web-example-terraform" {
  key_name = "web-example"
  public_key = "${file("ssh/id_rsa.pub")}"
}
