
# locals {
#   s3_bucket = "${data.aws_caller_identity.current.account_id}-data-archive"
#   s3_bucket_arn = "arn:aws:s3:::${data.aws_caller_identity.current.account_id}-data-archive"
#   s3_bucket_splat = "arn:aws:s3:::${data.aws_caller_identity.current.account_id}-data-archive/*"
# }

module "db" {
  # https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
  # https://github.com/terraform-aws-modules/terraform-aws-rds/blob/v3.3.0/examples/complete-oracle/main.tf
  source  = "terraform-aws-modules/rds/aws"
  version = "3.3.0"

  # The name of the database to create. Upper is required by Oracle.
  # Can't be more than 8 characters.
  name = upper(var.database_name)

  #-----------------------------------------------------------------------------
  # Define references to the parameter group. This module does not create it.
  create_db_parameter_group = false
  # When this rds/aws module is set to create a default parameter group,
  # it takes the name parameter above and uses it
  # to create the parameter group name. This parameter group name can't be
  # capitalized. However, Oracle requires that the database
  # name be capitalized. Therefore, I'm hard coding the
  # parameter group name.
  parameter_group_name = aws_db_parameter_group.db_parameter_group.id
  # Yes, the parameter is "parameter_group_name", and yes, the corresponding
  # Terraform parameter is "id". Yes, it's confusing.
  #-----------------------------------------------------------------------------

  # parameter_group_use_name_prefix = false
  allocated_storage                     = var.allocated_storage
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  apply_immediately                     = var.apply_immediately
  backup_retention_period               = var.backup_retention_period
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  create_db_option_group                = false
  create_db_subnet_group                = true
  create_random_password                = false
  db_instance_tags                      = var.tags
  db_subnet_group_tags                  = var.tags
  deletion_protection                   = var.deletion_protection
  enabled_cloudwatch_logs_exports       = ["alert", "trace", "listener"]
  engine                                = var.engine
  engine_version                        = var.engine_version
  family                                = var.family
  identifier                            = var.instance_name
  instance_class                        = var.instance_type
  license_model                         = var.license_model
  major_engine_version                  = var.major_engine_version
  max_allocated_storage                 = var.max_allocated_storage
  monitoring_interval                   = var.monitoring_interval
  multi_az                              = var.multi_az
  option_group_name                     = aws_db_option_group.oracle_rds[0].name
  password                              = random_password.root_password.result
  skip_final_snapshot                   = var.skip_final_snapshot
  snapshot_identifier                   = var.snapshot_identifier
  storage_encrypted                     = true
  subnet_ids                            = var.subnet_ids
  tags                                  = var.tags
  username                              = var.username # defaults to root
  vpc_security_group_ids                = [aws_security_group.db_security_group.id]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  # create_monitoring_role                = true
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
}

#-----------------------------------------------------------------------------
# Define the paramter group explicitly. Do not let the db module above
# create it. This is all to get around the issue with Oracle requiring
# database names to be in CAPS and
resource "aws_db_parameter_group" "db_parameter_group" {
  name_prefix = var.instance_name
  description = "Terraform managed parameter group for ${var.instance_name}"
  family      = var.family
  tags        = var.tags
  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

#-----------------------------------------------------------------------------
# Define the option group explicitly so we can implement S3 integration
resource "aws_db_option_group" "oracle_rds" {
  count                    = 1
  name_prefix              = var.instance_name
  option_group_description = "Oracle RDS Option Group managed by Terraform."
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  option {
    option_name = "S3_INTEGRATION"
  }

}

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
  name               = "rds-enhanced-monitoring-${lower(var.instance_name)}"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
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
  db_instance_identifier = module.db.db_instance_id
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.s3_data_archive.arn
}

resource "aws_iam_role" "s3_data_archive" {
  name               = "s3-data-archive-${lower(var.instance_name)}"
  assume_role_policy = data.aws_iam_policy_document.assume_s3_data_archive_role_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_data_archive" {
  role = aws_iam_role.s3_data_archive.name
  # The actions the role can execute
  policy_arn = aws_iam_policy.s3_data_archive.arn
}

resource "aws_iam_policy" "s3_data_archive" {
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
