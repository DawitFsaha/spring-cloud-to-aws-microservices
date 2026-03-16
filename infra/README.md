# Infra Starter Templates (CloudFormation)

This folder contains starter CloudFormation templates using the stack split you requested:

1. `network-stack.yaml`
2. `observability-stack.yaml`
3. `data-stack.yaml`
4. `messaging-stack.yaml`
5. `registry-stack.yaml`
6. `compute-base-stack.yaml`
7. `services-stack.yaml`
8. `edge-stack.yaml`

## Quick Notes

- These are **starter** templates intended to accelerate demo setup and teardown.
- They are parameterized for cross-stack wiring and export/import style naming.
- `services-stack.yaml` deploys `product-service`, `stock-service`, `order-service` by default.
- `api-gateway` service is optional in `services-stack.yaml` (`DeployApiGatewayService=false` by default).

## Deployment Order

Use this order:

1. `network-stack`
2. `observability-stack`
3. `data-stack`
4. `messaging-stack`
5. `registry-stack`
6. `compute-base-stack`
7. `services-stack`
8. `edge-stack`

## Teardown Order

Delete in reverse order:

1. `edge-stack`
2. `services-stack`
3. `compute-base-stack`
4. `registry-stack`
5. `messaging-stack`
6. `data-stack`
7. `observability-stack`
8. `network-stack`

## Example AWS CLI Deploy Commands

Adjust `PROJECT`, `ENV`, and file paths as needed.

```bash
PROJECT=cs590-microservices
ENV=demo

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-network \
  --template-file infra/network-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ProjectName=${PROJECT} Environment=${ENV}

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-observability \
  --template-file infra/observability-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ProjectName=${PROJECT} Environment=${ENV}

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-data \
  --template-file infra/data-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=${PROJECT} Environment=${ENV} \
    PrivateDataSubnetAId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateDataSubnetAId'].Value" --output text) \
    PrivateDataSubnetBId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateDataSubnetBId'].Value" --output text) \
    DocDbSecurityGroupId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-DocDbSecurityGroupId'].Value" --output text)

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-messaging \
  --template-file infra/messaging-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=${PROJECT} Environment=${ENV} \
    PrivateAppSubnetAId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetAId'].Value" --output text) \
    PrivateAppSubnetBId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetBId'].Value" --output text) \
    MskSecurityGroupId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-MskSecurityGroupId'].Value" --output text)

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-registry \
  --template-file infra/registry-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=${PROJECT} Environment=${ENV} \
    VpcId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-VpcId'].Value" --output text)

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-compute-base \
  --template-file infra/compute-base-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ProjectName=${PROJECT} Environment=${ENV}

# Replace image URIs before running this
aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-services \
  --template-file infra/services-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=${PROJECT} Environment=${ENV} \
    EcsClusterArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-EcsClusterArn'].Value" --output text) \
    TaskExecutionRoleArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-TaskExecutionRoleArn'].Value" --output text) \
    TaskRoleArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-TaskRoleArn'].Value" --output text) \
    NamespaceId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-CloudMapNamespaceId'].Value" --output text) \
    NamespaceName=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-CloudMapNamespaceName'].Value" --output text) \
    PrivateAppSubnetAId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetAId'].Value" --output text) \
    PrivateAppSubnetBId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetBId'].Value" --output text) \
    EcsServiceSecurityGroupId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-EcsServiceSecurityGroupId'].Value" --output text) \
    ProductMongoUriSecretArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-ProductMongoUriSecretArn'].Value" --output text) \
    StockMongoUriSecretArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-StockMongoUriSecretArn'].Value" --output text) \
    OrderMongoUriSecretArn=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-OrderMongoUriSecretArn'].Value" --output text) \
    KafkaBootstrapBrokers=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-MskBootstrapBrokers'].Value" --output text) \
    ProductServiceImageUri=<product-image-uri> \
    StockServiceImageUri=<stock-image-uri> \
    OrderServiceImageUri=<order-image-uri>

aws cloudformation deploy \
  --stack-name ${PROJECT}-${ENV}-edge \
  --template-file infra/edge-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=${PROJECT} Environment=${ENV} \
    VpcId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-VpcId'].Value" --output text) \
    PrivateAppSubnetAId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetAId'].Value" --output text) \
    PrivateAppSubnetBId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-PrivateAppSubnetBId'].Value" --output text) \
    AlbSecurityGroupId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-AlbSecurityGroupId'].Value" --output text) \
    VpcLinkSecurityGroupId=$(aws cloudformation list-exports --query "Exports[?Name=='${PROJECT}-${ENV}-VpcLinkSecurityGroupId'].Value" --output text)
```

## Manual Steps Recommended for Demo

- Push service images to ECR and update image URI parameters.
- Validate MSK topic presence (`order-created`, `order-cancelled`); create manually if needed.
- Optionally add Cognito JWT authorizer resources to `edge-stack.yaml` after first successful deploy.

## Important Starter Limitations

- `services-stack.yaml` currently uses Cloud Map registration and does not attach ECS services to ALB target groups.
- `edge-stack.yaml` creates ALB target groups and listener rules, but ECS target registration is left for a follow-up update.
- If you want, the next step is to add **ALB attachment support** directly in `services-stack.yaml` with target group parameters.
