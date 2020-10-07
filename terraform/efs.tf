# To secure this use Access Points
# The used Bitnami Image renders this a bit harder however

resource "aws_efs_file_system" "this" {
  creation_token = "${local.app_name}-EFS-moodle"
  # No options here, must be encrypted
  encrypted = true
  # Best practice use a CMK
  # kms_key_id     = "TBC"

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-EFS-moodle"
    },
  )
}

resource "aws_efs_mount_target" "this" {
  count           = local.subnet_count
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = element(var.private_subnets, count.index)
  security_groups = [aws_security_group.efs_internal_sg.id]
}

resource "aws_efs_file_system" "that" {
  creation_token = "${local.app_name}-EFS-moodledata"
  # No options here, must be encrypted
  encrypted = true
  # Best practice use a CMK
  # kms_key_id     = "TBC"

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-EFS-moodledata"
    },
  )
}

resource "aws_efs_mount_target" "that" {
  count           = local.subnet_count
  file_system_id  = aws_efs_file_system.that.id
  subnet_id       = element(var.private_subnets, count.index)
  security_groups = [aws_security_group.efs_internal_sg.id]
}