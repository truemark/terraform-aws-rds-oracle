This repository creates an Oracle RDS database instance. 

## Example Usage
```
module "db" {
  source                          = "truemark/aws-rds-oracle/aws"
  version                         = "0.0.1"
  database_name                   = "DBNAME"
  allocated_storage               = 100
  archive_bucket_name             = "my-archive-bucket-name"
  auto_minor_version_upgrade      = false
  deletion_protection             = true
  engine                          = "oracle-se2"
  engine_version                  = "19.0.0.0.ru-2022-01.rur-2022-01.r1"
  family                          = "oracle-se2-19"
  instance_name                   = local.name
  instance_type                   =  "db.m6i.large" 
  license_model                   = "bring-your-own-license"
  major_engine_version            = "19"
  monitoring_interval             = 60
  multi_az                        = false
  random_password_length          = 16
  skip_final_snapshot             = false
  store_master_password_as_secret = true
  subnet_ids                      = [ "subnet-0613436966e999", "subnet-0613436966ea998" ]
  vpc_id                          = "vpc-0a6c8fae7776adb32"
}
```
## Parameters
The following parameters are supported:

- allocated_storage
- allowed_cidr_blocks
- apply_immediately
- archive_bucket_name
- auto_minor_version_upgrade
- backup_retention_period
- ca_cert_identifier
- copy_tags_to_snapshot
- create_security_group
- database_name
- db_parameter_group_tags
- db_parameters
- deletion_protection
- egress_cidrs
- engine
- engine_version
- family
- ingress_cidrs
- instance_name
- instance_type
- license_model
- major_engine_version
- max_allocated_storage
- monitoring_interval
- multi_az
- options
- option_group_description
- preferred_backup_window
- preferred_maintenance_window
- random_password_length
- security_group_tags
- share
- share_tags
- skip_final_snapshot
- snapshot_identifier
- store_master_password_as_secret
- subnet_ids
- tags
- username
- vpc_id
