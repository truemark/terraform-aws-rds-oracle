variable "allocated_storage" {
  description = "Storage size in GB."
  default     = 100
}

variable "allowed_cidr_blocks" {
  description = "A list of CIDR blocks which are allowed to access the database"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "apply_immediately" {
  description = "Determines whether or not any DB modifications are applied immediately, or during the maintenance window"
  type        = bool
  default     = true
}

variable "archive_bucket_name" {
  description = "The S3 bucket this db has access to for expdp/impdp."
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "How long to keep backups for (in days)"
  type        = number
  default     = 7
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

variable "copy_tags_to_snapshot" {
  description = "Copy all cluster tags to snapshots"
  default     = false
}

variable "create_db_option_group" {
  description = "Whether to create the db option group for the RDS instance"
  default     = false
  type        = bool
}

variable "create_db_parameter_group" {
  description = "Whether to create the db parameter group for the RDS instance"
  default     = false
  type        = bool
}

variable "create_random_password" {
  description = "Whether to create random password for RDS primary cluster"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Whether to create the security group for the RDS instance"
  default     = true
  type        = bool
}

variable "create_db_subnet_group" {
  description = "Whether to create the db subnet group for the RDS instance"
  default     = true
  type        = bool
}

variable "custom_iam_instance_profile" {
  description = "RDS custom iam instance profile"
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name for the database within Oracle."
  type        = string
  default     = ""
}

variable "db_instance_create_timeout" {
  description = "Timeout in minutes to wait when creating the DB instance."
  type        = number
  default     = 90
}

variable "db_instance_update_timeout" {
  description = "Timeout in minutes to wait when updating the DB instance."
  type        = number
  default     = 90
}

variable "db_instance_delete_timeout" {
  description = "Timeout in minutes to wait when deleting the DB instance."
  type        = number
  default     = 45
}

variable "db_parameter_group_tags" {
  description = "A map of tags to add to the aws_db_parameter_group resource if one is created."
  default     = {}
}

variable "db_parameters" {
  description = "Map of parameters to use in the aws_db_parameter_group resource"
  type        = list(map(any))
  default     = [{}]
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "egress_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "engine" {
  description = "Oracle database engine."
  type        = string
  default     = "oracle-se2"
}

variable "engine_version" {
  description = "Oracle database engine version."
  type        = string
  default     = "12.1.0.2.v19"
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "oracle-se2-12.1"
}

variable "ingress_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "instance_name" {
  description = "Name for the Oracle RDS instance. This will display in the console."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Instance type to use at master instance. If instance_type_replica is not set it will use the same type for replica instances"
  type        = string
  default     = "db.r4.large"
}

variable "is_custom" {
  type    = bool
  default = false
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used. Be sure to use the full ARN, not a key alias."
  type        = string
  default     = null
}

variable "license_model" {
  description = "The licensing model for Oracle on RDS."
  type        = string
  default     = "license-included"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Oracle database engine version."
  type        = string
  default     = "12.1"
}

variable "master_iops" {
  description = "The iops to associate with the master db instance storage."
  type        = number
  default     = null
}

variable "max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 60
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "option_group_name" {
  description = "Name of the option group"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data. Valid values are `7`, `731` (2 years) or a multiple of `31`"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "When to perform DB backups"
  type        = string
  default     = "02:00-03:00" # 7PM-8PM MST
}

variable "preferred_maintenance_window" {
  description = "When to perform DB maintenance"
  type        = string
  default     = "sat:03:00-sat:05:00" # 8PM-10PM MST
}

variable "random_password_length" {
  description = "The length of the password to generate for root user."
  default     = 16
}

variable "security_group_tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}

variable "share" {
  default = false
  type    = bool
}

variable "share_tags" {
  description = "Additional tags for the resource access manager share."
  type        = map(string)
  default     = {}
}

variable "skip_final_snapshot" {
  description = "Should a final snapshot be created on cluster destroy"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "DB snapshot to create this database from"
  type        = string
  default     = null
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
  type        = string
  default     = "gp3"
}

variable "store_master_password_as_secret" {
  description = "Toggle on or off storing the root password in Secrets Manager."
  default     = true
}

variable "subnet_ids" {
  description = "List of subnet IDs to use"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "username" {
  description = "The master database account to create."
  default     = "root"
}

variable "vpc_id" {
  description = "The ID of the VPC to provision into"
  type        = string
}

variable "time_zone" {
  description = "The Oracle database time zone"
  type        = string
  default     = "UTC"
}

variable "agent_registration_password" {
  description = "Specifies the password which agent uses to register with OMS"
  type        = string
  default     = "password"
}

variable "allow_tls_only" {
  description = "Configures the OEM Agent to support only TLSv1 protocol while the Agent listens as a server"
  type        = string
  default     = "false"
}

variable "minimum_tls_version" {
  description = "Specifies the minimum TLS version supported by the OEM Agent while the Agent listens as a server"
  type        = string
  default     = "TLSv1"
}

variable "oms_host" {
  description = "Specifies the OMS host which agent communicates to"
  type        = string
  default     = ""
}

variable "oms_port" {
  description = "Specifies the OMS port which agent communicates to"
  type        = string
  default     = "4903"
}

variable "tls_cipher_suite" {
  description = "Configures the OEM Agent to support only TLSv1 protocol while the Agent listens as a server"
  type        = string
  default     = ""
}

variable "db_options" {
  description = "Map of options"
  type        = any
  default     = []
}

variable "option_group_description" {
  description = "The description of the option group"
  type        = string
  default     = null
}