# EKS Terraform Layout

Mỗi layer là một apply root độc lập, có backend state riêng và `terraform.tfvars` riêng.

```text
layer1-network/   # VPC, public/private subnet, NAT gateway
layer2-storage/   # ECR repository, CloudWatch log group cho EKS control-plane logging
layer3-compute/   # EKS cluster + 1 managed node group cố định 2 node
layer4-platform/  # IRSA role cho ESO (backend/frontend) + AWS Load Balancer Controller
modules/          # module dùng chung: vpc, ecr, monitoring, eks, irsa
```

Workload (Argo CD, External Secrets Operator, AWS Load Balancer Controller,
app frontend/backend) không nằm ở đây — xem [../helm-chart/](../helm-chart/).

## Yêu cầu trước khi apply

Backend dùng S3 (`bucket = "eks-lab-tfstate-770880870430"`, key set trong mỗi
`terraform.tf`, locking bằng `use_lockfile = true` — tính năng S3 native locking từ
Terraform ≥ 1.10, không cần DynamoDB). Bucket này **không tự tạo** — tạo trước bằng
tay hoặc bootstrap script. Tên bucket đã gắn hậu tố account ID để đảm bảo unique toàn
cầu (tên `eks-lab-tfstate` trơn đã bị tài khoản AWS khác chiếm mất):

```powershell
aws s3api create-bucket --bucket eks-lab-tfstate-770880870430 --region ap-southeast-1 `
  --create-bucket-configuration LocationConstraint=ap-southeast-1
aws s3api put-bucket-versioning --bucket eks-lab-tfstate-770880870430 `
  --versioning-configuration Status=Enabled
```

Cấu hình AWS credentials trước (`aws configure` hoặc biến môi trường).

## Thứ tự apply

```powershell
cd layer1-network; terraform init; terraform apply
cd ../layer2-storage; terraform init; terraform apply
cd ../layer3-compute; terraform init; terraform apply
cd ../layer4-platform; terraform init; terraform apply
```

`layer3-compute` đọc output của `layer1-network` (subnet) và `layer2-storage`
(ECR url) qua `terraform_remote_state`. `layer4-platform` đọc output của
`layer3-compute` (`oidc_provider_arn`, `oidc_issuer_url`, `cluster_name`).

Sau khi `layer3-compute` apply xong:

```powershell
aws eks update-kubeconfig --region ap-southeast-1 --name eks-lab-dev
kubectl get nodes
```

Sau khi `layer4-platform` apply xong, lấy 3 ARN role để điền vào Helm values
(xem [../helm-chart/docs/AWS-CONVERSION.md](../helm-chart/docs/AWS-CONVERSION.md)):

```powershell
terraform output backend_secrets_role_arn
terraform output frontend_config_role_arn
terraform output alb_controller_role_arn
```

Rồi set giá trị thật của secret backend (không quản lý qua Terraform, tránh
plaintext trong state/tfvars):

```powershell
aws secretsmanager put-secret-value --secret-id eks-lab/dev/backend/database-url `
  --secret-string '{"DATABASE_URL":"postgres://..."}'
```

## Ghi chú

- Node group cố định **đúng 2 node** (`node_desired_size = node_min_size = node_max_size = 2`
  trong `layer3-compute/terraform.tfvars`).
- `cluster_name` phải khớp giữa `layer1-network`, `layer2-storage` và
  `layer3-compute/eks_name` — dùng để tag subnet và đặt tên log group đúng chuẩn EKS.
- `layer4-platform` không tạo workload gì trong cluster — chỉ tạo IAM
  role/policy phía AWS. Helm chart ở `../helm-chart/` mới tạo `ServiceAccount`
  Kubernetes tương ứng để "nhận" các role này (IRSA).
- Muốn thêm database sau này thì tạo `layer5-database` theo đúng khuôn này
  (đọc remote state của `layer1-network` để lấy `private_subnet_ids`).

Giải thích chi tiết từng resource: [COMPONENTS.md](COMPONENTS.md).
