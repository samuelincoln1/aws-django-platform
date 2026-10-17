# Cost Analysis

Monthly estimate for the infrastructure in this repository, running 24/7 in
`us-east-1` with on-demand pricing (730 hours/month). Prices are AWS list
prices at the time of writing — check the
[AWS Pricing Calculator](https://calculator.aws/) before relying on them.

Traffic assumptions: ~1M requests and ~100 GB transferred per month, ~30
releases per month.

## Summary

| Service | Configuration | Monthly (USD) |
|---|---|---:|
| ECS Fargate | 2 tasks × (1 vCPU, 2 GB) — scales to 6 | 72.08 – 216.24 |
| VPC interface endpoints | 4 endpoints × 2 AZs | 58.50 |
| RDS PostgreSQL | db.t3.micro Multi-AZ, 20 GB gp3 | 31.40 |
| Application Load Balancer | 1 ALB, ~1 LCU average | 22.27 |
| AWS WAF | 1 web ACL, 5 rules, 1M requests | 10.60 |
| CloudWatch | Logs + Container Insights | 8.65 |
| CodePipeline + CodeBuild | ~30 releases | 3.00 |
| Secrets Manager | 2 secrets | 0.80 |
| ECR | ~3 GB of images | 0.30 |
| S3 | Static files + pipeline artifacts | 0.15 |
| CloudFront | 100 GB, 1M HTTPS requests | 0.00 (free tier) |
| **Total** | **2 tasks (minimum)** | **≈ 208** |
| **Total** | **6 tasks (maximum)** | **≈ 352** |

Not included: Route 53 hosted zone ($0.50/month, if used), data transfer to the
internet beyond the CloudFront free tier, and taxes.

## Details

### ECS Fargate

- $0.04048 per vCPU-hour + $0.004445 per GB-hour
- One task (1 vCPU, 2 GB): (0.04048 + 2 × 0.004445) × 730 = **$36.04/month**
- 2 tasks (minimum): **$72.08** · 6 tasks (maximum): **$216.24**

Fargate is the largest and the most elastic line: autoscaling keeps 2 tasks
under normal load and only adds tasks while average CPU stays above 70%.

### VPC endpoints

- Interface endpoints are billed **per endpoint per AZ**: $0.01/hour
- 4 endpoints (ECR API, ECR Docker, CloudWatch Logs, Secrets Manager) × 2 AZs ×
  $0.01 × 730 = **$58.40** + $0.01/GB processed (~$0.10)
- The S3 gateway endpoint is free

### RDS PostgreSQL

| Item | Calculation | USD |
|---|---|---:|
| db.t3.micro, Multi-AZ | $0.036/hour × 730 | 26.28 |
| 20 GB gp3, Multi-AZ | $0.23/GB-month × 20 | 4.60 |
| Automated backups (7 days) | Free up to the provisioned storage size | 0.00 |
| Performance Insights | 7-day retention is free | 0.00 |
| Enhanced Monitoring | CloudWatch Logs ingestion | ~0.50 |
| **Total** | | **31.40** |

Multi-AZ doubles the instance and storage cost in exchange for a synchronous
standby and automatic failover (typically 60–120 seconds).

### Application Load Balancer

- $0.0225/hour × 730 = $16.43
- LCUs: $0.008/LCU-hour; ~1 LCU average at this traffic = $5.84
- **Total: $22.27**

### AWS WAF

- Web ACL: $5.00
- Rules: $1.00 each × 5 (3 AWS managed rule groups, rate limit, geo block) = $5.00
- Requests: $0.60 per million = $0.60
- **Total: $10.60**

### CloudFront

CloudFront's always-free tier covers 1 TB of data transfer out and 10 million
HTTP(S) requests per month, which is above the assumed traffic. Data transfer
from the ALB and S3 to CloudFront is not charged. Beyond the free tier:
$0.085/GB and $0.01 per 10,000 HTTPS requests.

### CloudWatch

- Log ingestion (application, RDS, CodeBuild), ~5 GB: $2.50
- Log storage: ~$0.15
- Container Insights metrics: ~$6.00 (estimate)
- **Total: ~$8.65**

### CI/CD

- CodeBuild `BUILD_GENERAL1_SMALL`: $0.005/minute; ~14 minutes per release
  (build + deploy) × 30 = 420 minutes ≈ $2.10
- CodePipeline V2: $0.002 per action-minute after 100 free minutes ≈ $0.64
- **Total: ~$3.00**

## Design decision: VPC endpoints instead of NAT gateways

The ECS tasks run in private subnets. They need to reach a few AWS services
(ECR, CloudWatch Logs, Secrets Manager, S3) and nothing else on the internet.
There are two ways to give them that access:

| | VPC endpoints (chosen) | 2 NAT gateways (one per AZ) | 1 NAT gateway |
|---|---:|---:|---:|
| Fixed cost | $58.40 | $65.70 | $32.85 |
| Data processing | $0.01/GB | $0.045/GB | $0.045/GB |
| Survives an AZ outage | Yes | Yes | No |
| Outbound internet access | **None** | Full | Full |

The fixed costs are close. The deciding factors are:

1. **Security:** without a route to the internet, a compromised container has
   no way to download tooling or exfiltrate data to an arbitrary host. Each
   service the tasks can reach is listed explicitly.
2. **Data processing:** every image pull, log line and S3 upload through a NAT
   gateway costs 4.5× more per GB than through an endpoint.

The trade-off is flexibility: calling any external API (payment provider,
email service, ...) would require adding a NAT gateway or a specific endpoint.

## Ways to reduce cost

1. **Right-size the tasks.** 1 vCPU / 2 GB is generous for this application.
   0.5 vCPU / 1 GB halves the Fargate line (~$36/month at minimum capacity).
   Decide using Container Insights CPU/memory data.
2. **Fargate Spot** for part of the capacity (capacity provider strategy with
   an on-demand base) — Spot tasks cost up to 70% less but can be interrupted.
3. **Compute Savings Plans** for the baseline that always runs.
4. **Graviton (ARM64)** tasks are ~20% cheaper; requires building an ARM image.
5. **Non-production environments:** single-AZ RDS, a single task, interface
   endpoints in one AZ only (halves that line, at the cost of cross-AZ
   dependency), and scheduled scaling to zero outside working hours.
6. **AWS Budgets** alerts to catch unexpected growth early.
