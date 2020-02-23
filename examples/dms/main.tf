module "dms-mongo" {
  source = "../../dms"
  replication_task_id = "repltask"  
  map_rule_path = "${path.module}/config/map_rule.json"
  repl_task_path = "${path.module}/config/repl_task_settings.json"
  mongodb_server_name = "HOST_DOMAIN_OR_IP"
  subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  security_groups = ["sg-12"]
  is_multi_az = false
  username = "USER_NAME"
  password = "SUPER_SECRET_PASSWORD"
  dynamodb_target_name = "dynamodbtarget"
  mongodb_database_name = "airlinedb"
  nesting_level = "one"
}

