#!/bin/bash

# Script para habilitar Enhanced Observability no Container Insights
# Este script deve ser executado após o deploy do Terraform

set -e

# Variáveis - ajuste conforme necessário
CLUSTER_NAME="${1:-django-app-cluster}"  # Use o nome do seu cluster
AWS_REGION="${2:-us-east-1}"

echo "Habilitando Enhanced Observability para o cluster: $CLUSTER_NAME"
echo "Região: $AWS_REGION"

# Verificar se o cluster existe
echo "Verificando se o cluster existe..."
aws ecs describe-clusters \
    --cluster "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query 'clusters[0].clusterName' \
    --output text

if [ $? -ne 0 ]; then
    echo "Erro: Cluster $CLUSTER_NAME não encontrado na região $AWS_REGION"
    exit 1
fi

# Habilitar Enhanced Observability
echo "Habilitando Enhanced Observability..."
aws ecs put-cluster-capacity-providers \
    --cluster "$CLUSTER_NAME" \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --region "$AWS_REGION"

# Aguardar um pouco para a configuração ser aplicada
echo "Aguardando configuração ser aplicada..."
sleep 10

# Verificar Container Insights
echo "Verificando status do Container Insights..."
aws ecs describe-clusters \
    --cluster "$CLUSTER_NAME" \
    --include INSIGHTS \
    --region "$AWS_REGION" \
    --query 'clusters[0].settings'

echo ""
echo "✅ Enhanced Observability habilitado com sucesso!"
echo ""
echo "Agora você pode:"
echo "1. Acessar CloudWatch Console"
echo "2. Ir para Insights > Container Insights"
echo "3. Selecionar 'ECS Services' ou 'ECS Tasks'"
echo "4. Filtrar pelo cluster: $CLUSTER_NAME"
echo "5. Ver métricas detalhadas por task e container"
echo ""
echo "Nota: Pode levar alguns minutos para as métricas aparecerem." 