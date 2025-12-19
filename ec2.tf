resource "aws_instance" "private_ec2" {
  count         = 4
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = element(
    [aws_subnet.private_1.id, aws_subnet.private_2.id],
    count.index % 2
  )

  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false


}
