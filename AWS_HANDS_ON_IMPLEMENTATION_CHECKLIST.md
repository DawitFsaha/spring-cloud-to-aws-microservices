# AWS Hands-On Implementation Checklist (CloudFormation-First)

This document is the practical companion to `AWS_CLOUD_ARCHITECTURE_GUIDE.md`.

It gives you:

- exact key migration mapping from the current project,
- dependency changes per service,
- CloudFormation-first deployment order,
- manual steps only where they make sense for demo speed.

---

## 1) Strategy: CloudFormation-First for Easy Demo Teardown

Use multiple small CloudFormation stacks instead of one giant stack.

Recommended stack split:

1. `network-stack` (VPC, subnets, NAT, route tables, security groups)
2. `observability-stack` (CloudWatch log groups, alarms, dashboards, X-Ray settings)
3. `data-stack` (DocumentDB or Atlas networking, Secrets Manager secrets)
4. `messaging-stack` (MSK cluster, topics if using automation)
5. `registry-stack` (Cloud Map namespace, optional Service Connect shared config)
6. `compute-base-stack` (ECR repos, ECS cluster, task execution roles)
7. `services-stack` (ECS task definitions + ECS services for each microservice)
8. `edge-stack` (ALB internal, API Gateway HTTP API + VPC Link, WAF, optional Cognito)

Why this helps:

- clean create/update/delete lifecycle,
- easier troubleshooting by layer,
- easy demo reset by deleting stacks in reverse order.

---

## 2) Current Keys and What They Become in AWS

These are keys already present in your repo and runtime (`docker-compose.yml`, `application*.properties|yml`, `logback-spring.xml`, Java annotations).

## 2.1 Keys currently used

- `CONFIG_SERVER_URL`
- `CONSUL_HOST`, `CONSUL_PORT`, `CONSUL_INSTANCE_ID`
- `KAFKA_BOOTSTRAP_SERVERS`
- `MONGODB_HOST`
- `ZIPKIN_ENDPOINT`
- `LOGSTASH_HOST`, `LOGSTASH_PORT`
- `CONFIG_GIT_URI`, `CONFIG_GIT_LABEL` (config-server)
- `spring.config.import=optional:configserver:...`
- Feign logical names: `product-service`, `stock-service`
- Kafka topics in code: `order-created`, `order-cancelled`
- Kafka listener group in code: `stock-service-group`

## 2.2 Target keys for AWS

Replace runtime inputs with these AWS-oriented keys:

- `APP_ENV` (`dev`, `demo`, `prod`)
- `AWS_REGION`
- `SPRING_PROFILES_ACTIVE=aws`
- `SPRING_APPLICATION_NAME`
- `SPRING_DATA_MONGODB_URI` (from Secrets Manager)
- `SPRING_KAFKA_BOOTSTRAP_SERVERS` (MSK brokers)
- `SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL` (for MSK mode)
- `SPRING_KAFKA_PROPERTIES_SASL_MECHANISM` (if IAM/SCRAM)
- `SPRING_KAFKA_PROPERTIES_SASL_JAAS_CONFIG` (if SCRAM)
- `MANAGEMENT_TRACING_SAMPLING_PROBABILITY`
- `MANAGEMENT_OTLP_TRACING_ENDPOINT` or X-Ray exporter config
- `LOGGING_LEVEL_ROOT` (optional)

For service discovery in ECS/Cloud Map:

- prefer DNS names in env/config such as:
  - `PRODUCT_SERVICE_BASE_URL=http://product-service.demo.local`
  - `STOCK_SERVICE_BASE_URL=http://stock-service.demo.local`

Then wire Feign clients via `url` where needed for explicit control.

---

## 3) Dependency and Config Changes by Service

> Notes:
>
> 1. Your repo currently imports almost all runtime config from Spring Config Server, so exact property sets from the external Git config repo are not visible here.
> 2. Checklist below is based on exact keys present in this repo plus AWS target keys needed for migration.

## 3.1 `api-gateway` service checklist

Current evidence:

- `spring.config.import=optional:configserver:${CONFIG_SERVER_URL:http://localhost:8888}`
- dependencies include `spring-cloud-starter-gateway`, `spring-cloud-starter-consul-discovery`, `spring-cloud-starter-config`

### Dependencies

- Remove:
  - `org.springframework.cloud:spring-cloud-starter-consul-discovery`
  - `org.springframework.cloud:spring-cloud-starter-config` (if config-server is retired)
- Keep:
  - `spring-cloud-starter-gateway` only if this service stays
- Add (if staying):
  - `software.amazon.awssdk:ssm`
  - `software.amazon.awssdk:secretsmanager`
  - OpenTelemetry/X-Ray-compatible tracing dependency set (ADOT path)

### Config keys

- Remove:
  - `spring.config.import=optional:configserver:...`
- Add/Use:
  - `SPRING_PROFILES_ACTIVE=aws`
  - `APP_ENV`, `AWS_REGION`
  - upstream route URLs as Cloud Map or ALB targets

### Deploy decision

- Preferred in AWS: retire this service and use API Gateway HTTP API + ALB.
- Keep only if you need custom Spring filters or route logic not feasible in API Gateway policies.

---

## 3.2 `product-service` checklist

Current evidence:

- `spring.config.import=optional:configserver:${CONFIG_SERVER_URL:http://localhost:8888}`
- Feign: `@FeignClient(name = "stock-service")`
- Consul + Config dependencies in `pom.xml`

### Dependencies

- Remove:
  - `spring-cloud-starter-consul-discovery`
  - `spring-cloud-starter-config` (after migration)
- Keep:
  - `spring-cloud-starter-openfeign`
  - `spring-boot-starter-data-mongodb`
- Add:
  - AWS SDK modules for SSM/Secrets Manager or Spring Cloud AWS equivalent
  - OTEL/X-Ray compatible tracing dependency

### Config keys

- Remove/retire:
  - `CONFIG_SERVER_URL`, `CONSUL_HOST`, `CONSUL_PORT`
- Add:
  - `SPRING_DATA_MONGODB_URI`
  - `STOCK_SERVICE_BASE_URL` (if Feign uses explicit URL)
  - tracing/logging keys used in CloudWatch/X-Ray path

### Code adjustments

- Option A (simple): keep `@FeignClient(name = "stock-service")` and ensure DNS/service discovery resolves in ECS.
- Option B (explicit): switch to `@FeignClient(name = "stock-service", url = "${STOCK_SERVICE_BASE_URL}")`.

---

## 3.3 `stock-service` checklist

Current evidence:

- `spring.config.import=optional:configserver:${CONFIG_SERVER_URL:http://localhost:8888}`
- Kafka listeners hardcode:
  - topic `order-created`
  - topic `order-cancelled`
  - group `stock-service-group`

### Dependencies

- Remove:
  - `spring-cloud-starter-consul-discovery`
  - `spring-cloud-starter-config` (after migration)
- Keep:
  - `spring-kafka`
  - `spring-boot-starter-data-mongodb`
- Add:
  - MSK auth dependency if using IAM auth (e.g., aws-msk-iam-auth)
  - SSM/SecretsManager config-loading support
  - OTEL/X-Ray compatible tracing dependency

### Config keys

- Remove/retire:
  - `CONFIG_SERVER_URL`, `CONSUL_*`, `KAFKA_BOOTSTRAP_SERVERS` (compose-style)
- Add:
  - `SPRING_KAFKA_BOOTSTRAP_SERVERS`
  - `SPRING_KAFKA_CONSUMER_GROUP_ID=stock-service-group` (if externalized)
  - `ORDER_CREATED_TOPIC=order-created` and `ORDER_CANCELLED_TOPIC=order-cancelled` (optional externalization)
  - `SPRING_DATA_MONGODB_URI`

### Code adjustments

- Recommended: externalize topic names and group ID to properties (so env-based overrides are possible per stage).

---

## 3.4 `order-service` checklist

Current evidence:

- Feign clients to `product-service` and `stock-service`
- Resilience4j circuit breaker names:
  - `productService`, `stockService`
- Kafka producer topics hardcoded:
  - `order-created`, `order-cancelled`

### Dependencies

- Remove:
  - `spring-cloud-starter-consul-discovery`
  - `spring-cloud-starter-config` (after migration)
- Keep:
  - `spring-cloud-starter-openfeign`
  - `spring-cloud-starter-circuitbreaker-resilience4j`
  - `spring-kafka`
  - `spring-boot-starter-data-mongodb`
- Add:
  - MSK IAM auth dependency if needed
  - SSM/SecretsManager config-loading support
  - OTEL/X-Ray compatible tracing dependency

### Config keys

- Remove/retire:
  - `CONFIG_SERVER_URL`, `CONSUL_*`, old compose `KAFKA_BOOTSTRAP_SERVERS`
- Add:
  - `PRODUCT_SERVICE_BASE_URL`, `STOCK_SERVICE_BASE_URL` (if explicit URL strategy)
  - `SPRING_KAFKA_BOOTSTRAP_SERVERS`
  - `SPRING_DATA_MONGODB_URI`
  - resilience keys (externalized):
    - `resilience4j.circuitbreaker.instances.productService.*`
    - `resilience4j.circuitbreaker.instances.stockService.*`
    - `resilience4j.retry.instances.productService.*`
    - `resilience4j.retry.instances.stockService.*`

### Code adjustments

- Externalize Kafka topics into properties for environment flexibility.
- Keep fallback semantics unchanged (they already map well to AWS runtime failures).

---

## 3.5 `config-server` checklist

Current evidence:

- This service is Spring Cloud Config Server + Consul registration.
- Keys include: `CONFIG_GIT_URI`, `CONFIG_GIT_LABEL`, `CONSUL_*`, Zipkin settings.

### Migration path

- Short-term (optional): keep temporarily during transition.
- Target: decommission and replace with:
  - AWS AppConfig (runtime feature/config toggles)
  - SSM Parameter Store (plain config)
  - Secrets Manager (secrets)

### Dependency action

- When fully migrated, this service can be retired entirely.

---

## 4) CloudFormation Stack-by-Stack Build Checklist

## 4.1 `network-stack`

Resources:

- VPC
- 2 public subnets + 2 private app subnets + 2 private data subnets
- Internet Gateway + NAT Gateways
- route tables
- security groups for ALB, ECS, MSK, DocumentDB

Outputs (used by other stacks):

- `VpcId`
- `PrivateAppSubnetIds`
- `PrivateDataSubnetIds`
- `AlbSecurityGroupId`
- `EcsServiceSecurityGroupId`

## 4.2 `compute-base-stack`

Resources:

- ECS cluster
- ECR repos (`api-gateway`, `product-service`, `stock-service`, `order-service`)
- IAM roles:
  - ECS task execution role
  - task role base policy (CloudWatch, X-Ray, SSM, Secrets Manager)

Outputs:

- `EcsClusterName`
- `TaskExecutionRoleArn`
- `TaskRoleArn`
- ECR repo URIs

## 4.3 `registry-stack`

Resources:

- Cloud Map private DNS namespace (e.g., `demo.local`)
- optional service discovery services

Outputs:

- namespace id/name

## 4.4 `data-stack`

Resources:

- Option A: DocumentDB cluster + subnet group + SG
- Option B: if Atlas is used, keep Atlas provisioning manual; only CF for VPC endpoints/networking and secret storage
- Secrets Manager secrets for each DB URI

Outputs:

- per-service Mongo URI secret ARNs

## 4.5 `messaging-stack`

Resources:

- Amazon MSK cluster
- SG and subnet group
- optional custom resource/topic bootstrap automation

Outputs:

- bootstrap broker endpoints
- auth mode metadata

## 4.6 `observability-stack`

Resources:

- CloudWatch log groups per service
- retention policies
- metric filters and alarms
- dashboards
- X-Ray sampling/permissions

Outputs:

- log group names

## 4.7 `services-stack`

Resources:

- ECS task definitions (one per service)
- ECS services (desired count; stock-service can start with 2 tasks)
- Service Connect/Cloud Map registration
- container env vars and secrets

Important env/secrets wiring:

- env:
  - `SPRING_PROFILES_ACTIVE=aws`
  - `AWS_REGION`
  - `APP_ENV`
- secrets:
  - `SPRING_DATA_MONGODB_URI`
  - any Kafka SASL secrets if SCRAM

## 4.8 `edge-stack`

Resources:

- Internal ALB + target groups + listener rules
- API Gateway HTTP API + VPC Link + integrations/routes
- WAF association
- optional Cognito user pool + app client + JWT authorizer

Outputs:

- invoke URL

---

## 5) Deployment Order (Exact Runbook)

1. Deploy `network-stack`
2. Deploy `compute-base-stack`
3. Deploy `registry-stack`
4. Deploy `data-stack`
5. Deploy `messaging-stack`
6. Deploy `observability-stack`
7. Build/push Docker images to ECR (`api-gateway` only if retained)
8. Deploy `services-stack`
9. Deploy `edge-stack`
10. Smoke tests through API Gateway

Teardown order (reverse):

1. `edge-stack`
2. `services-stack`
3. `observability-stack`
4. `messaging-stack`
5. `data-stack`
6. `registry-stack`
7. `compute-base-stack`
8. `network-stack`

---

## 6) Manual Steps (Where It Makes Sense)

These steps are reasonable to do manually for demos:

- Create initial MSK topics (`order-created`, `order-cancelled`) manually using Kafka admin client.
- Create/update Cognito test users manually.
- Manually upload AppConfig profiles/feature flags for quick iteration.
- Manually run a one-time DB seed job (if avoiding migration tooling for demo).

Everything else should stay in CloudFormation for repeatability and easy cleanup.

---

## 7) Service-by-Service Done Criteria

## 7.1 `product-service`

- running as ECS task
- registered/discoverable via Cloud Map/Service Connect
- reads Mongo URI from Secrets Manager
- can call `stock-service` via service discovery DNS
- logs visible in CloudWatch

## 7.2 `stock-service`

- running with desired count >= 2
- consumes MSK topic `order-created`
- consumer group stable (`stock-service-group`)
- confirms reservations successfully
- logs and traces visible

## 7.3 `order-service`

- calls `stock-service` and `product-service` successfully
- publishes to `order-created` and `order-cancelled`
- circuit breaker and retry metrics observable
- cancellation flow works end-to-end

## 7.4 `api-gateway` (if retained)

- all routes healthy behind ALB
- no Consul or Config Server dependency left
- external traffic still enters via AWS API Gateway

## 7.5 `config-server`

- no service depends on `spring.config.import=configserver`
- can be undeployed without impact

---

## 8) Practical Property Template (Per Service, ECS Task Definition)

Use this as the baseline environment/secrets model for each microservice task:

Environment variables:

- `SPRING_APPLICATION_NAME=<service-name>`
- `SPRING_PROFILES_ACTIVE=aws`
- `APP_ENV=demo`
- `AWS_REGION=<region>`
- `SPRING_KAFKA_BOOTSTRAP_SERVERS=<from messaging-stack output>` (for order/stock)
- `PRODUCT_SERVICE_BASE_URL=http://product-service.demo.local` (order-service)
- `STOCK_SERVICE_BASE_URL=http://stock-service.demo.local` (order/product when explicit URL strategy is used)

Secrets (Secrets Manager references):

- `SPRING_DATA_MONGODB_URI`
- any Kafka auth secret fields (if SCRAM)

---

## 9) What to Change First in Code (Minimal-Risk Sequence)

1. Externalize hardcoded Kafka topic names/group IDs in `order-service` and `stock-service`.
2. Add AWS profile config files (`application-aws.properties`) per service.
3. Remove Consul-specific dependencies and properties.
4. Move away from `spring.config.import=configserver`.
5. Add AWS config/secrets integration.
6. Switch tracing/logging outputs to CloudWatch/X-Ray path.
7. Deploy to ECS and validate service-to-service calls.

This sequence lets you migrate incrementally while preserving current business behavior.
