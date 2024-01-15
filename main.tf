module "db" {
  # https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
  # https://github.com/terraform-aws-modules/terraform-aws-rds/blob/v3.3.0/examples/complete-oracle/main.tf
  source  = "terraform-aws-modules/rds/aws"
  version = "5.6.0"

  # The name of the database to create. Upper is required by Oracle.
  # Can't be more than 8 characters.
  db_name = upper(var.database_name)

  #-----------------------------------------------------------------------------
  # Define references to the parameter group. This module does not create it.
  create_db_parameter_group = var.create_db_parameter_group
  # When this rds/aws module is set to create a default parameter group,
  # it takes the name parameter above and uses it
  # to create the parameter group name. This parameter group name can't be
  # capitalized. However, Oracle requires that the database
  # name be capitalized. Therefore, I'm hard coding the
  # parameter group name.
  parameter_group_name = var.is_custom == true ? null : aws_db_parameter_group.db_parameter_group[0].id
  # Yes, the parameter is "parameter_group_name", and yes, the corresponding
  # Terraform parameter is "id". Yes, it's confusing.
  #-----------------------------------------------------------------------------

  # parameter_group_use_name_prefix = false
  allocated_storage                     = var.allocated_storage
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  apply_immediately                     = var.apply_immediately
  backup_retention_period               = var.backup_retention_period
  ca_cert_identifier                    = var.ca_cert_identifier
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  create_db_option_group                = var.create_db_option_group # not used in custom set to false
  create_db_subnet_group                = var.create_db_subnet_group
  create_random_password                = var.create_random_password
  custom_iam_instance_profile           = var.custom_iam_instance_profile
  db_instance_tags                      = var.tags
  db_subnet_group_description           = "Subnet group for ${var.instance_name}. Managed by Terraform."
  db_subnet_group_name                  = var.instance_name
  db_subnet_group_tags                  = var.tags
  deletion_protection                   = var.deletion_protection
  enabled_cloudwatch_logs_exports       = var.is_custom == true ? [] : ["alert", "trace", "listener"]
  engine                                = var.engine
  engine_version                        = var.engine_version
  family                                = var.family
  identifier                            = var.instance_name
  instance_class                        = var.instance_type
  iops                                  = var.master_iops
  kms_key_id                            = var.kms_key_id
  license_model                         = var.license_model
  maintenance_window                    = var.preferred_maintenance_window
  major_engine_version                  = var.major_engine_version
  max_allocated_storage                 = var.is_custom == true ? 0 : var.max_allocated_storage
  monitoring_interval                   = var.is_custom == true ? 0 : var.monitoring_interval
  monitoring_role_arn                   = var.is_custom == true ? null : aws_iam_role.rds_enhanced_monitoring[0].arn
  multi_az                              = var.is_custom == true ? false : var.multi_az
  option_group_name                     = var.instance_name
  options                               = var.db_options
  password                              = var.store_master_password_as_secret ? random_password.root_password.result : null
  performance_insights_enabled          = var.is_custom == true ? false : var.performance_insights_enabled
  performance_insights_retention_period = var.is_custom == true ? 0 : var.performance_insights_retention_period
  skip_final_snapshot                   = var.skip_final_snapshot
  snapshot_identifier                   = var.snapshot_identifier
  storage_encrypted                     = true
  storage_type                          = var.storage_type
  subnet_ids                            = var.subnet_ids
  tags                                  = var.tags
  username                              = var.username # defaults to root
  vpc_security_group_ids                = [aws_security_group.db_security_group.id]

  timeouts = {
    create = "${var.db_instance_create_timeout}m"
    update = "${var.db_instance_update_timeout}m"
    delete = "${var.db_instance_delete_timeout}m"
  }

  # create_monitoring_role                = true
}

#-----------------------------------------------------------------------------
# Define the paramter group explicitly. Do not let the db module above
# create it. This is all to get around the issue with Oracle requiring
# database names to be in CAPS and
resource "aws_db_parameter_group" "db_parameter_group" {
  count       = var.is_custom ? 0 : 1
  name_prefix = var.instance_name
  description = "Terraform managed parameter group for ${var.instance_name}"
  family      = var.family
  tags        = var.tags
  dynamic "parameter" {
    for_each = var.db_options
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

#-----------------------------------------------------------------------------
# Define the option group explicitly so we can implement S3 integration
#resource "aws_db_option_group" "oracle_rds" {
#  count                    = var.is_enable_s3integration ? 1 : 0
#  name_prefix              = var.instance_name
#  option_group_description = "Oracle RDS Option Group managed by Terraform."
#  engine_name              = var.engine
#  major_engine_version     = var.major_engine_version
#
#  option {
#    option_name = "S3_INTEGRATION"
#  }
#}

#resource "aws_db_option_group" "oracle_rds3" {
#  count                    = var.is_enable_timezone ? 1 : 0
#  name_prefix              = var.instance_name
#  option_group_description = "Oracle RDS Option Group managed by Terraform."
#  engine_name              = var.engine
#  major_engine_version     = var.major_engine_version
#
#  option {
#    option_name = "Timezone"
#    option_settings {
#      name  = "TIME_ZONE"
#      value = var.time_zone
#    }
#  }
#}

#resource "aws_db_option_group" "oracle_rds2" {
#  count                    = var.is_enable_oem ? 1 : 0
#  name_prefix              = var.instance_name
#  option_group_description = "Oracle RDS Option Group managed by Terraform."
#  engine_name              = var.engine
#  major_engine_version     = var.major_engine_version
#
#  option {
#    option_name = "OEM_AGENT"
#    option_settings {
#      name  = "AGENT_REGISTRATION_PASSWORD"
#      value = var.agent_registration_password
#    }
#    option_settings {
#      name  = "ALLOW_TLS_ONLY"
#      value = var.allow_tls_only
#    }
#    option_settings {
#      name  = "MINIMUM_TLS_VERSION"
#      value = var.minimum_tls_version
#    }
#    option_settings {
#      name  = "OMS_HOST"
#      value = var.oms_host
#    }
#    option_settings {
#      name  = "OMS_PORT"
#      value = var.oms_port
#    }
#    option_settings {
#      name  = "TLS_CIPHER_SUITE"
#      value = var.tls_cipher_suite
#    }
#  }
#}

#-----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db" {
  count       = var.store_master_password_as_secret ? 1 : 0
  name_prefix = "database/${var.instance_name}/master-"
  description = "Master password for ${var.username} in ${var.instance_name}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  count     = var.store_master_password_as_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.db[count.index].id
  secret_string = jsonencode({
    "username"       = "root"
    "password"       = random_password.root_password.result
    "host"           = module.db.db_instance_address
    "port"           = module.db.db_instance_port
    "dbname"         = module.db.db_instance_name
    "connect_string" = "${module.db.db_instance_endpoint}/${upper(var.database_name)}"
    "engine"         = "oracle"
  })
}
resource "random_password" "root_password" {
  length  = var.random_password_length
  special = false
  # An Oracle password cannot start with a number.
  # There is no way to tell Terraform to create a password that starts
  # with a character only that I am aware of, so don't use
  # numbers at all. Same with special characters (Oracle only allows #, but a pw
  # can't start with #).
  numeric = false
}

data "aws_secretsmanager_secret_version" "db" {
  count = var.store_master_password_as_secret ? 1 : 0
  # There will only ever be one password here. Hard coding the index.
  secret_id  = aws_secretsmanager_secret.db[0].id
  depends_on = [aws_secretsmanager_secret_version.db]
}

#-----------------------------------------------------------------------------

resource "aws_security_group" "db_security_group" {
  name   = var.instance_name
  vpc_id = var.vpc_id
  tags   = var.tags

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  ingress {
    from_port   = 3872
    to_port     = 3872
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  # TODO Lock this down later
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.egress_cidrs
  }
}

################################################################################
# Create an IAM role to allow enhanced monitoring
################################################################################

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count              = var.is_custom ? 0 : 1
  name               = "rds-enhanced-monitoring-${lower(var.instance_name)}"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.is_custom ? 0 : 1
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

################################################################################
# Create an IAM role to allow access to the s3 data archive bucket
################################################################################

resource "aws_db_instance_role_association" "s3_data_archive" {
  count                  = var.is_custom ? 0 : 1
  db_instance_identifier = module.db.db_instance_id
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.s3_data_archive[0].arn
}

resource "aws_iam_role" "s3_data_archive" {
  count              = var.is_custom ? 0 : 1
  name               = "s3-data-archive-${lower(var.instance_name)}"
  assume_role_policy = data.aws_iam_policy_document.assume_s3_data_archive_role_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_data_archive" {
  count = var.is_custom ? 0 : 1
  role  = aws_iam_role.s3_data_archive[0].name
  # The actions the role can execute
  policy_arn = aws_iam_policy.s3_data_archive[0].arn
}

resource "aws_iam_policy" "s3_data_archive" {
  count       = var.is_custom ? 0 : 1
  name        = "s3-data-archive-${lower(var.instance_name)}"
  description = "Terraform managed RDS Instance policy."
  policy      = data.aws_iam_policy_document.exec_s3_data_archive.json
}

data "aws_iam_policy_document" "assume_s3_data_archive_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "exec_s3_data_archive" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      "arn:aws:s3:::${var.archive_bucket_name}",
      "arn:aws:s3:::${var.archive_bucket_name}/*"
    ]

    effect = "Allow"

  }
}
