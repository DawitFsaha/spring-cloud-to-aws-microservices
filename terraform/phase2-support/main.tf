module "observability" {
  source = "../modules/observability"

  project_name = var.project_name
  environment  = var.environment
  alarm_email  = var.alarm_email
}
