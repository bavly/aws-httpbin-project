# AWS Httpbin MicroK8s Deployment (Free-tier Friendly)

This project deploys [httpbin](https://github.com/kennethreitz/httpbin) in AWS EC2 using **MicroK8s**.  
It exposes:  

- `/get` publicly over HTTPS  
- `/post` internally restricted via Security Group (NodePort 30999)

---

## 🚀 Project Structure

```
aws-httpbin-project/
├── terraform/       # IaC: VPC, subnet, EC2, security groups
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/         # EC2 bootstrap (MicroK8s + TLS + deploy manifests)
│   └── Installation_K8s_openssl.sh
├── k8s/             # Kubernetes manifests
│   ├── httpbin-deployment.yaml
│   ├── httpbin-service-public.yaml
│   ├── httpbin-service-private.yaml
│   ├── httpbin-ingress.yaml
└── README.md        # This file
```

---

## ⚡ Why MicroK8s (vs Minikube)

| Feature            | Minikube           | MicroK8s                                |
| ------------------ | ------------------ | --------------------------------------- |
| Resource footprint | High (VM)          | Low (native)                            |
| Networking         | Host-only / VM NAT | Host network / NodePort works naturally |
| Free-tier friendly | Not ideal          | ✅ Works well                            |
| Production addons  | Limited            | ✅ dns, ingress, metrics, etc.           |
| Automation on EC2  | Complex            | ✅ Easy via user_data                   |

---

## 🌐 Network Design

### Public Subnet

```
[Internet]
   |
   v
+------------------+
| Internet Gateway |
+------------------+
        |
        v
+------------------+
| Public Subnet    |  (route 0.0.0.0/0 → IGW)
+------------------+
        |
        v
+-------------------------+
| EC2 (MicroK8s)          |  <-- Has public IP
| httpbin pod             |
+-------------------------+
        |
        ├── /get  → exposed via Ingress HTTPS → accessible publicly
        └── /post → NodePort 30999 restricted via Security Group → VPC-only
```

- **Free-tier safe:** No NAT Gateway required.  
- **Private access** simulated via Security Group rules.  

---

## 🔑 TLS Setup

- TLS cert is generated automatically using **OpenSSL** in the bootstrap script.  
- Stored as Kubernetes secret `httpbin-tls`.  
- Ingress terminates HTTPS using this secret.  

---

## ⚠️ Notes

1. **NodePort Range:** Kubernetes only allows NodePorts between **30000–32767**.  

2. **Ubuntu Recommended:**  
   - `ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*`  
   - Works out-of-the-box with MicroK8s + snap.

3. **added .gitignore file**
   - so that to ignore large file like terraform-provider-aws_v6.13.0_x5.exe & *.tfstate

4. **Create key pair name**
   - Must create it in AWS in key value of EC2 then add the value in variables.tf file in the default part
   - `default     = "terraform-Keypair`  

---

## 🛠️ Deployment Steps

1. Clone the repo and enter terraform folder:

```bash
cd aws-httpbin-project/terraform
terraform init
terraform plan
terraform apply
```

2. After apply, get the EC2 public IP via Terraform output:

```bash
terraform output ec2_public_ip
```

Or store it in a variable for easier testing:

```bash
export EC2_IP=$(terraform output -raw ec2_public_ip)
```

3. SSH into the EC2 instance (optional, for debugging):

```bash
ssh -i <your-key.pem> ubuntu@$EC2_IP
```

4. Check pods and ingress:

```bash
microk8s kubectl get pods -n httpbin
microk8s kubectl get ingress -n httpbin
```

---

## 🔍 Testing Endpoints

With the `EC2_IP` variable set:

- **Public `/get` (HTTPS)**:

```bash
curl -k https://$EC2_IP/get
```

- **Private `/post` (NodePort 30999, VPC-only)**:

```bash
curl -k -X POST https://$EC2_IP:30999/post
```

> Only works from machines inside the VPC (restricted via Security Group).

---

## 🧹 Cleanup

To avoid AWS charges:

```bash
cd aws-httpbin-project/terraform
terraform destroy
```}]}

