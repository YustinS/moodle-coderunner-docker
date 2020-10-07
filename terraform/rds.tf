# THIS IS A BASIC EXAMPLE.
# UPDATE FOR ANY SORT OF Non-PoC USAGE

resource "aws_db_instance" "moodle" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mariadb"
  engine_version         = "10.4"
  instance_class         = "db.t2.micro"
  identifier             = lower("${local.app_name}-DB")
  name                   = local.db_name
  username               = local.db_user
  password               = local.db_password
  db_subnet_group_name   = lower("${local.app_name}-DB-Subnets")
  tags                   = local.common_tags
  vpc_security_group_ids = [aws_security_group.rds_internal_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "app" {
  name       = lower("${local.app_name}-DB-Subnets")
  subnet_ids = var.private_subnets

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-DB-Subnet-Group"
    }
  )
}