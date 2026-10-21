# Giải thích các component

Tài liệu này giải thích từng resource trong [modules/](modules/) — resource đó là
gì, tại sao cần, và nó nối với resource nào khác. Đọc [README.md](README.md) để biết
thứ tự apply; đọc file này để hiểu bên trong từng layer đang tạo ra cái gì.

## layer1-network → modules/vpc

| Resource | Vai trò |
|---|---|
| `aws_vpc` | Mạng ảo riêng chứa toàn bộ hạ tầng. CIDR mặc định `10.0.0.0/16`. |
| `aws_internet_gateway` | Cổng cho VPC ra internet — subnet **public** gắn route tới đây. |
| `aws_subnet.public` (2, một mỗi AZ) | Đặt NAT gateway và (sau này) load balancer công khai. `map_public_ip_on_launch = true` nên instance trong đây có IP public tự động. |
| `aws_subnet.private` (2, một mỗi AZ) | Đặt **EKS node** — worker node không có IP public, ra internet gián tiếp qua NAT. |
| `aws_eip.nat` + `aws_nat_gateway` | 1 NAT gateway duy nhất (đặt ở public subnet đầu tiên) để subnet private tải image, gọi API AWS... mà không expose ra ngoài. Dùng 1 cái để tiết kiệm chi phí (~$0.045/giờ + data processing) thay vì 1 NAT/AZ. |
| `aws_route_table.public` + association | Route `0.0.0.0/0` → Internet Gateway, gán cho 2 subnet public. |
| `aws_route_table.private` + association | Route `0.0.0.0/0` → NAT Gateway, gán cho 2 subnet private. |

**Vì sao 2 AZ?** EKS control plane bắt buộc subnet trải trên ít nhất 2 Availability
Zone để chịu lỗi (control plane tự nhân bản across AZ).

**Tag `kubernetes.io/cluster/<tên-cluster>` và `kubernetes.io/role/elb` /
`internal-elb`**: đánh dấu để về sau AWS Load Balancer Controller (nếu cài) tự
động biết subnet nào để đặt ALB/NLB public hay internal — không phải làm gì thêm ở
bước này, chỉ là chuẩn bị sẵn.

## layer2-storage → modules/ecr, modules/monitoring

| Resource | Vai trò |
|---|---|
| `aws_ecr_repository` | Registry riêng để build & push Docker image của bạn lên, thay vì kéo từ Docker Hub. Node group (layer3) đã có sẵn quyền pull qua policy `AmazonEC2ContainerRegistryReadOnly`. |
| `aws_cloudwatch_log_group` (`modules/monitoring`) | Tạo trước log group `/aws/eks/<cluster>/cluster` với `retention_in_days` cụ thể. Nếu không tạo trước, EKS vẫn tự tạo log group này khi bật `enabled_cluster_log_types`, nhưng sẽ **không có hạn giữ log** (lưu vĩnh viễn → tốn phí). Tên phải khớp chính xác định dạng `/aws/eks/<cluster_name>/cluster`. |

Layer này độc lập với layer1 (không cần VPC info) nên không có `data.tf`.

## layer3-compute → modules/eks

Đây là phần chính, nằm trong [modules/eks/main.tf](modules/eks/main.tf).

### 1. IAM role cho cluster (`aws_iam_role.cluster` + `aws_iam_role_policy_attachment.cluster_policy`)
EKS control plane (do AWS vận hành, bạn không thấy VM) cần một role để tự quản lý
ENI, security group... trong VPC của bạn. Role này assume bởi service
`eks.amazonaws.com`, gắn managed policy `AmazonEKSClusterPolicy`.

### 2. `aws_eks_cluster.this`
Chính là control plane Kubernetes (API server, etcd, scheduler...) — AWS quản lý
phần này hoàn toàn, bạn chỉ trả phí theo giờ (~$0.10/giờ) + phí node bên dưới.
- `vpc_config.subnet_ids` = **subnet private** từ layer1 → ENI của control plane
  nằm trong VPC của bạn để giao tiếp với node.
- `enabled_cluster_log_types = ["api", "audit"]` (xem `terraform.tfvars`) → log
  API server và audit log được đẩy vào CloudWatch log group đã tạo ở layer2.
- `access_config.authentication_mode = "API"` → dùng **EKS Access Entries** (cơ
  chế mới) thay cho `aws-auth` ConfigMap cũ để cấp quyền Kubernetes RBAC theo
  IAM identity.

### 2b. `aws_eks_access_entry` + `aws_eks_access_policy_association` (`admin`)
EKS chỉ tự cấp quyền `system:masters` ngầm cho đúng IAM identity đã chạy
`terraform apply` tạo cluster — **không cấp cho ai khác**, kể cả bạn đăng nhập lại
AWS Console bằng session khác hay root account. Thiếu bước này thì Console báo
`Unauthorized` khi mở tab **Resources** của cluster, và `kubectl` báo tương tự dù
`aws eks update-kubeconfig` chạy thành công (kubeconfig lấy được, nhưng gọi API
bị 401).

`var.admin_principal_arns` (set trong `layer3-compute/terraform.tfvars`) liệt kê
IAM user/role ARN nào được cấp `AmazonEKSClusterAdminPolicy` — quyền admin toàn
cluster. Muốn thêm người khác truy cập, thêm ARN của họ vào danh sách này rồi
`apply` lại, không cần sửa gì trong cluster bằng tay.

### 3. OIDC provider (`data.tls_certificate` + `aws_iam_openid_connect_provider.cluster`)
Mỗi EKS cluster có sẵn một OIDC issuer URL (định danh cluster như một "identity
provider"). Đăng ký URL này làm `aws_iam_openid_connect_provider` trong IAM cho
phép **IRSA — IAM Roles for Service Accounts**: sau này một Pod trong cluster có
thể assume một IAM role AWS trực tiếp (ví dụ để đọc S3, gọi RDS...) mà không cần
nhét access key vào container. `data.tls_certificate` chỉ để lấy thumbprint chứng
chỉ TLS của issuer — bước bắt buộc để đăng ký OIDC provider với IAM.

Chưa dùng ngay ở bước này (chưa có service account nào), nhưng dựng sẵn để layer
sau (ví dụ Argo CD, cluster-autoscaler, external-dns...) có thể IRSA ngay không
cần sửa lại cluster.

### 4. IAM role cho node (`aws_iam_role.node` + 3 policy attachment)
Khác với role cluster, role này gắn cho **EC2 instance** (worker node), assume bởi
`ec2.amazonaws.com`. 3 managed policy bắt buộc:
- `AmazonEKSWorkerNodePolicy` — cho phép node đăng ký vào cluster, gọi API EKS.
- `AmazonEKS_CNI_Policy` — cho phép plugin mạng (VPC CNI) gán IP từ VPC cho Pod.
- `AmazonEC2ContainerRegistryReadOnly` — cho phép node pull image từ ECR (bao gồm
  repo tạo ở layer2), không cần cấu hình `imagePullSecrets`.

### 5. `aws_eks_node_group.default`
Nhóm EC2 instance (managed node group — AWS tự tạo Auto Scaling Group phía sau,
tự vá OS, tự đăng ký/rút node khỏi cluster khi scale).
- `subnet_ids` = subnet **private** → node không có IP public, đúng chuẩn bảo mật.
- `scaling_config.desired/min/max_size = 2/2/2` (`terraform.tfvars`) → **cố định
  đúng 2 node**, không tự động scale.
- `instance_types = ["t3.small"]` (đổi ở `node_instance_type` trong tfvars nếu
  cần máy khoẻ hơn) — phải nằm trong danh sách free-tier-eligible của tài
  khoản này (`aws ec2 describe-instance-types --filters
  Name=free-tier-eligible,Values=true`), tài khoản bị giới hạn chỉ launch
  được các type đó.
- `lifecycle.ignore_changes = [scaling_config[0].desired_size]` — nếu sau này bật
  Cluster Autoscaler (nó tự sửa desired_size ngoài Terraform), lần `apply` kế
  tiếp sẽ không cố kéo desired_size về lại giá trị cũ trong tfvars.

## layer4-platform → modules/irsa

Layer này **không tạo Pod/workload nào** — chỉ tạo phía AWS những gì workload
sẽ cần khi Helm chart ở `../helm-chart/` được cài (xem
[../helm-chart/docs/AWS-CONVERSION.md](../helm-chart/docs/AWS-CONVERSION.md)
để biết phía Kubernetes dùng các role này thế nào).

### `modules/irsa` — module dùng chung, gọi 3 lần

IRSA (IAM Roles for Service Accounts) hoạt động dựa trên đúng OIDC provider đã
tạo ở `layer3-compute` (mục 3 phía trên): một IAM role có trust policy chỉ cho
phép **một `ServiceAccount` cụ thể** (namespace + tên) trong cluster assume —
không phải toàn bộ cluster, không phải node. Module nhận vào
`oidc_provider_arn`/`oidc_issuer_host` (từ `data.terraform_remote_state.compute`),
`namespace`, `service_account_name`, rồi tạo:
- `aws_iam_role` với `assume_role_policy` chứa 2 điều kiện `StringEquals` trên
  `<issuer>:sub` (đúng SA) và `<issuer>:aud` (`sts.amazonaws.com`).
- `aws_iam_role_policy_attachment` (nếu truyền `policy_arns` — managed policy có sẵn).
- `aws_iam_role_policy` inline (nếu truyền `inline_policy_json` — quyền tự viết).

### 3 role được tạo trong `main.tf`

| Role | Cấp quyền gì | ServiceAccount tương ứng bên Helm |
|---|---|---|
| `<cluster>-backend-secrets` | `secretsmanager:GetSecretValue` đúng 1 secret ARN | `be/backend-external-secrets` |
| `<cluster>-frontend-config` | `ssm:GetParameter*` đúng 1 path prefix | `fe/frontend-external-secrets` |
| `<cluster>-alb-controller` | Policy `AWSLoadBalancerControllerIAMPolicy` (tải nguyên văn từ repo chính thức `aws-load-balancer-controller`, lưu ở `files/alb_iam_policy.json`) | `kube-system/aws-load-balancer-controller` |

### `aws_secretsmanager_secret.backend_database_url`
Chỉ tạo **cái vỏ secret** (tên + tags) — Terraform không quản lý *giá trị* bên
trong. Lý do: giá trị thật (connection string DB) không nên nằm trong
`terraform.tfvars`/state ở dạng plaintext. Set giá trị bằng tay sau khi apply:

```powershell
aws secretsmanager put-secret-value --secret-id eks-lab/dev/backend/database-url `
  --secret-string '{"DATABASE_URL":"postgres://..."}'
```

### `aws_ssm_parameter.frontend` (`for_each` trên `var.frontend_parameters`)
Khác với secret backend, config frontend (`BACKEND_URL`...) không nhạy cảm nên
**quản lý thẳng qua Terraform** — thêm/sửa key trong `terraform.tfvars` rồi
`apply` là đủ, không cần chạm AWS CLI.

### Vì sao tách layer4 riêng thay vì gộp vào layer3-compute?
IRSA role gắn với **workload cụ thể** (backend, frontend, 1 controller), không
phải hạ tầng cluster. Team vận hành cluster (layer1-3) có thể khác team quản
lý ứng dụng (layer4) — tách state giúp đổi quyền 1 ứng dụng không đụng tới
cluster đang chạy.

## Vì sao tách layer thay vì 1 file?

- **State nhỏ, risk thấp**: sửa node group (layer3) không chạm tới state của VPC
  (layer1) — tránh trường hợp `terraform apply` ở compute vô tình đề xuất xoá/tạo
  lại subnet.
- **Áp dụng tuần tự có lý do**: network phải có trước để compute biết subnet nào;
  storage (ECR/log group) độc lập nên apply trước hay sau layer1 đều được, miễn
  trước layer3.
- **Owner khác nhau**: trong team thật, network team và platform team có thể
  quản lý state riêng, quyền IAM riêng cho từng layer.

## Sơ đồ phụ thuộc

```
layer1-network (VPC, subnet)
        │  private_subnet_ids
        ▼
layer3-compute (EKS cluster + node group) ◄── ecr_repository_url ── layer2-storage (ECR, log group)
        │  oidc_provider_arn, oidc_issuer_url, cluster_name
        ▼
layer4-platform (IRSA role: backend secrets, frontend config, ALB controller)
```
