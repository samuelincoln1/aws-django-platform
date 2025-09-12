# Avaliação de Custos

A infraestrutura implementada é robusta e preparada para receber alto tráfego sem quedas de performance. Além disso, diversas medidas de segurança foram implementadas, como AWS WAF para proteger a aplicação de ataques DDoS, SQL Injection, Cross Site Scripting (XSS) e outras vulnerabilidades comuns.

Tudo foi provisionado na AWS, o que gera custos mensais. Segue abaixo uma análise detalhada da previsão de custo para esta aplicação, bem como possíveis estratégias para reduzir os gastos sem comprometer segurança, escalabilidade, disponibilidade ou estabilidade.

## 1. Amazon ECS Fargate

**Configuração:**
- **CPU**: 1vCPU por task
- **Memória**: 2GB por task
- **Auto-scaling**: 2-6 tasks baseado no uso de CPU (70% target)
- **Estimativa de uso**: 4 tasks em média (cenário moderado)

**Custo**
- **CPU**: $0.04048 por vCPU por hora
- **Memória**: $0.004445 por GB por hora
- **Horas por mês**: 730 horas

**Custos estimados:**
- **Cenário mínimo (2 tasks)**: $72.08/mês
- **Cenário máximo (6 tasks)**: $216.24/mês

## 2. Amazon RDS PostgreSQL

**Configuração:**
- **Instância**: db.t3.micro
- **Multi-AZ**: habilitado
- **Armazenamento**: 20GB GP3 (auto-scaling até 100GB)
- **Backup**: 7 dias de retenção
- **Performance Insights**: habilitado

**Custo**
- **db.t3.micro**: $0.034/h → $49.64 (considerando Multi-AZ)
- **20GB GP3**: $0.115 por GB → $2.30
- **Backup Storage**: $0.095 por GB (estimado 25GB) → $2.38
- **Performance Insights**: $0.009/h → $6.57

**Custo estimado total**: $60.89/mês

## 3. Application Load Balancer

**Configuração:**
- **Quantidade**: 1 ALB
- **Processamento estimado**: 1GB/mês

**Custo**: $16.43/mês

## 4. Amazon S3 + CloudFront

### Configuração S3:
- **Storage**: Estimado 5GB de arquivos estáticos
- **Requests**: 10.000 GET, 1.000 PUT por mês
- **Versioning**: Habilitado

### Configuração CloudFront:
- **Distribuição**: 1 distribuição
- **Transfer**: Estimado 100GB/mês
- **Requests**: 1.000.000 requests/mês

**Cálculo de custos:**
- **S3 Storage 5GB**: $0.023 × 5GB = $0.12
- **S3 Requests GET**: $0.0004 × 10 = $0.004
- **S3 Requests PUT**: $0.005 × 1 = $0.005
- **CloudFront Transfer 100GB**: $0.085 × 100GB = $8.50
- **CloudFront Requests**: $0.0075 × 1M = $7.50

**Custo Estimado**: $16.13/mês

## 5. VPC Endpoints

### Configuração:
- **Interface Endpoints**: 4 endpoints (ECR API, ECR DKR, Logs, Secrets Manager)
- **Gateway Endpoint**: 1 endpoint (S3)
- **Processamento**: Estimado 10GB/mês

**Cálculo de custos:**
- **Interface Endpoints**: 4 × $7.30 × 730h/730h = $29.20
- **Processamento 10GB**: $0.01 × 10GB = $0.10

**Custo Estimado**: $29.30/mês

## 6. Amazon ECR
**Custo irrelevante**, poucas imagens Docker

## 7. AWS Secrets Manager
**Custo irrelevante**, poucos segredos

## 8. CloudWatch

**Configuração:**
- **Log Groups**: 3 grupos (ECS, CodeBuild, RDS)
- **Log Storage**: Estimado 5GB/mês
- **Métricas Customizadas**: 20 métricas

**Cálculo de custos:**
- **Log Ingestion 5GB**: $0.50 × 5GB = $2.50
- **Log Storage 5GB**: $0.03 × 5GB = $0.15
- **Métricas**: 20 × $0.30 = $6.00

**Custo Estimado**: $9.05/mês

---

## Resumo Total

**Considerando uso mínimo das instâncias (2 tasks)**: Aproximadamente $200 mensais

**Considerando uso máximo das instâncias (6 tasks)**: Aproximadamente $349 mensais

**Média**: $274.50

---

## Estratégias de Redução de Custos

Foram aplicadas diversas estratégias de redução. Por exemplo, foram implementados VPC Endpoints em vez de NAT Gateways para que as instâncias em subnets privadas possam acessar recursos AWS fora da VPC (como S3, Secrets Manager e CloudWatch).

Como as instâncias não precisam interagir com a internet, já que não acessam APIs ou serviços externos, é possível configurar a infraestrutura sem a utilização de NAT Gateways, recursos consideravelmente caros. O custo para os VPC Endpoints é de cerca de $30.00/mês, já o custo de 2 NAT Gateways (um para cada subnet pública) seria de $67.95/mês. Com essa estratégia a infraestrutura tem menos flexibilidade, já que os containers podem acessar apenas serviços AWS específicos, porém ela se torna muito mais barata.

### Outras estratégias de redução de custo incluem, mas não se limitam a:

- **Limitação de escalonamento horizontal**: no máximo 6 aplicações
- **Limitação de recursos por aplicação**: 1vCPU + 2GB RAM
- **Utilização de instância RDS básica**: t3.micro, atende à necessidade da aplicação com baixos custos

---

## Possíveis Ajustes ou Otimizações

Caso seja necessário realizar uma redução ainda maior de custo nesta infraestrutura, são possíveis algumas abordagens:

1. **Monitorar utilização real da aplicação**, para utilizar menos recursos computacionais por instância caso haja margem

2. **Considerar a utilização de ECS + EC2** em vez de Fargate, uma vez que seria possível utilizar instâncias mais baratas, como Spot Instances ou Reserved Instances

3. **Estabelecer budgets** e alertas de custo

4. **Avaliar trade-offs** entre custo e segurança

5. **Avaliar necessidade de utilizar banco de dados Multi-AZ**, uma vez que essa configuração dobra o custo (cópia do banco)