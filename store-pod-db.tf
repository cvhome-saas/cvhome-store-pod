module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "db-${var.project}-${var.pod.id}-${var.env}"
  description = "Postgres db security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Db access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]

  tags = var.tags
}


module "store-pod-db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "db-${var.project}-${var.pod.id}-${var.env}"

  engine            = "postgres"
  engine_version    = "17.4"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  family            = "postgres17"


  db_name  = "postgres"
  username = "postgres"
  port     = "5432"


  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.db_security_group.security_group_id]
  # DB subnet group

  create_db_option_group    = false
  create_db_parameter_group = false

  create_db_subnet_group = true
  subnet_ids             = var.database_subnets


  deletion_protection = false
  publicly_accessible = true
  skip_final_snapshot = true

  tags = var.tags
}