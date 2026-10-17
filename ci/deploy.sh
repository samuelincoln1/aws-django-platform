#!/usr/bin/env bash
# Releases IMAGE_URI to the ECS service:
#   1. registers a new task definition revision with the new image
#   2. runs migrations + collectstatic as a one-off task, before any traffic moves
#   3. points the service at the new revision and waits for the rollout
#
# Required env: IMAGE_URI CLUSTER SERVICE TASK_FAMILY CONTAINER_NAME SUBNETS SECURITY_GROUP
set -euo pipefail

echo "==> Registering task definition for $IMAGE_URI"
# Latest ACTIVE revision of the family = Terraform's configuration + previous image
aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --query taskDefinition \
  | jq --arg image "$IMAGE_URI" --arg name "$CONTAINER_NAME" '
      .containerDefinitions |= map(if .name == $name then .image = $image else . end)
      | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
            .compatibilities, .registeredAt, .registeredBy)' \
  > /tmp/task-definition.json

TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-definition.json \
  --query taskDefinition.taskDefinitionArn --output text)
echo "    $TASK_DEFINITION_ARN"

echo "==> Running migrations"
# Schema changes must stay compatible with the version still serving traffic
# (expand/contract), since old tasks keep running until the rollout finishes.
OVERRIDES=$(jq -n --arg name "$CONTAINER_NAME" '{containerOverrides: [{
  name: $name,
  command: ["sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput"]
}]}')

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEFINITION_ARN" \
  --launch-type FARGATE \
  --started-by "codebuild-release" \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" \
  --overrides "$OVERRIDES" \
  --query 'tasks[0].taskArn' --output text)
echo "    $TASK_ARN"

aws ecs wait tasks-stopped --cluster "$CLUSTER" --tasks "$TASK_ARN"

EXIT_CODE=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" \
  --query "tasks[0].containers[?name=='$CONTAINER_NAME'].exitCode | [0]" --output text)
if [[ "$EXIT_CODE" != "0" ]]; then
  echo "Migration task failed (exit code: $EXIT_CODE). Logs: CloudWatch, stream app/$CONTAINER_NAME/${TASK_ARN##*/}" >&2
  exit 1
fi

echo "==> Updating service $SERVICE"
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$TASK_DEFINITION_ARN" > /dev/null

# The circuit breaker rolls back failed deployments, so "stable" alone is not
# enough: wait until the rollout of *this* revision completes or fails.
for _ in $(seq 1 90); do
  STATE=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query "services[0].deployments[?taskDefinition=='$TASK_DEFINITION_ARN'].rolloutState | [0]" \
    --output text)
  case "$STATE" in
    COMPLETED) echo "==> Deployed $IMAGE_URI"; exit 0 ;;
    FAILED)    echo "Deployment failed and was rolled back" >&2; exit 1 ;;
    *)         sleep 10 ;;
  esac
done

echo "Timed out waiting for the deployment" >&2
exit 1
