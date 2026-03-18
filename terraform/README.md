# Terraform Deployment (CloudFormation Replacement)

This folder is the Terraform-based replacement for infrastructure provisioning.

## Target Region

- Region: `us-east-2`

## Deployment Phases

## Phase 1: Core Runtime Platform (`terraform/phase1-core`)

Phase 1 provisions everything required for the microservices to run:

- VPC, subnets, NAT, route tables, security groups
- ECS cluster, IAM task roles, ECR repositories
- Aurora PostgreSQL + datasource URL secrets in Secrets Manager
- Cloud Map service registry
- ALB + target groups + API Gateway HTTP API + VPC Link (+ optional WAF)
- ECS task definitions/services (`product`, `stock`, `order`, optional `api-gateway`)
- App config in Parameter Store

## Phase 2: Support Services (`terraform/phase2-support`)

Phase 2 provisions nice-to-have/operational services:

- CloudWatch log groups
- Metric filters, alarms, dashboard
- X-Ray sampling rule

## Kafka Strategy (Manual Cluster)

Kafka is intentionally **not** created by Terraform.

You create the cluster manually, then store bootstrap brokers in SSM Parameter Store:

- Parameter name:
  `/cs590-microservices/demo/config/kafka/bootstrap-brokers`

Terraform phase 1 can create this as a placeholder (`REPLACE_ME_KAFKA_BOOTSTRAP_BROKERS`) and ECS reads it at runtime.

After creating your Kafka cluster, update the value:

```bash
aws ssm put-parameter \
  --region us-east-2 \
  --name /cs590-microservices/demo/config/kafka/bootstrap-brokers \
  --type String \
  --value "b-1.example.us-east-2.kafka.amazonaws.com:9092,b-2.example.us-east-2.kafka.amazonaws.com:9092" \
  --overwrite
```

## Apply Order

1. `terraform/phase1-core` with `deploy_services = false` (core infra only)
2. Create Kafka manually in the same VPC and update SSM bootstrap brokers value
3. `terraform/phase1-core` again with `deploy_services = true` and service image URIs
4. `terraform/phase2-support`

## Teardown Order

1. `terraform/phase2-support`
2. `terraform/phase1-core`

## Phase 1 Commands

```bash
cd terraform/phase1-core
cp backend.tf.example backend.tf   # edit values first
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

For a safe first run before Kafka exists, keep `deploy_services = false` in `terraform.tfvars`.

After Kafka is created and the SSM bootstrap parameter is updated, set:

- `deploy_services = true`
- `product_service_image_uri`, `stock_service_image_uri`, `order_service_image_uri`

Then run `terraform plan` and `terraform apply` again in `terraform/phase1-core`.

## Phase 2 Commands

```bash
cd terraform/phase2-support
cp backend.tf.example backend.tf   # edit values first
terraform init
terraform plan
terraform apply
```

## Notes

- Keep separate state files for each phase.
- Do not manage the same resources with CloudFormation and Terraform simultaneously.
- If you used CloudFormation before, destroy/import-state carefully before running Terraform in the same AWS account.
