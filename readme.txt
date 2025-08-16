

---

# Task 3 — Terraform + Docker on Azure Free Tier (Linux VM)

Provision a **Docker NGINX container** using **Terraform** on an Azure Free Tier **Ubuntu 22.04** VM (size **B1s**).
Result: site available on **http\://\<PUBLIC\_IP>:8080**.

---

## 1) What this repo contains

```
Task3/
├── main.tf          # Terraform config: Docker provider + nginx container
├── variables.tf     # container name and external port (8080)
├── outputs.tf       # prints container name/id + URL
└── README.md        # this file
# (Optional) logs/   # init/plan/apply/destroy logs if you save them
```

**Terraform files (for reference):**

`main.tf`

```hcl
terraform {
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}
provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = false
}

resource "docker_container" "web" {
  name  = var.container_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}
```

`variables.tf`

```hcl
variable "container_name" {
  description = "Container name"
  type        = string
  default     = "tf-nginx"
}

variable "external_port" {
  description = "Host port to expose NGINX on"
  type        = number
  default     = 8080
}
```

`outputs.tf`

```hcl
output "container_name" { value = docker_container.web.name }
output "container_id"   { value = docker_container.web.id }
output "url"            { value = "http://localhost:${var.external_port}" }
```

---

## 2) Azure (Portal) — create the VM

1. **Resource Group**

   * Portal → Resource groups → **Create**
   * Name: `rg-task3-linux`, Region: **East US** → **Create**.

2. **Ubuntu VM**

   * Portal → Virtual machines → **Create → Azure virtual machine**
   * Resource group: `rg-task3-linux`
   * VM name: `vm-task3-linux`, Region: **East US**
   * Image: **Ubuntu Server 22.04 LTS (Gen2)**
   * Size: **Standard B1s**
   * Authentication: **SSH public key** (recommended)

     * Username: `azureuser`
     * Paste the contents of your `id_ed25519.pub` if prompted
   * Inbound port: **SSH (22)**
   * **Create** → wait for deployment.

3. **Open app port (8080)**

   * VM → **Networking** → **Add inbound port rule**
   * TCP **8080**, Name `app-8080`, Source **My IP** (or Any for demo) → **Add**.

4. **Copy Public IP**

   * VM Overview → Public IP (e.g., `20.x.x.x`).

---

## 3) Connect & install tools (on the VM)

**SSH to the VM (from your PC):**

```bash
ssh azureuser@<PUBLIC_IP>
```

**Install Terraform + Docker (copy the whole block):**

```bash
# Essentials
sudo apt-get update
sudo apt-get install -y curl unzip ca-certificates gnupg lsb-release

# Terraform (HashiCorp repo)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update && sudo apt-get install -y terraform

# Docker Engine
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker azureuser
newgrp docker

# Verify
terraform -version
docker --version
```

> If Terraform still isn’t found, install the binary directly:
> `ARCH=$(dpkg --print-architecture); TF_VER=1.9.5; cd /tmp; curl -fsSLO https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${ARCH}.zip; sudo unzip -o terraform_${TF_VER}_linux_${ARCH}.zip -d /usr/local/bin; terraform -version`

---

## 4) Run Terraform

```bash
# Put files under ~/Task3 (or clone your repo there), then:
cd ~/Task3
terraform fmt -recursive
terraform init
terraform plan
terraform apply -auto-approve
```

**Check it works**

* VM shell: `curl -I http://localhost:8080`
* Browser on your PC: `http://<PUBLIC_IP>:8080` → NGINX welcome page 🎉
* See container: `docker ps` (should map `0.0.0.0:8080->80/tcp`)

---

## 5) Save logs (optional but recommended)

```bash
mkdir -p logs
terraform init  2>&1 | tee logs/init.log
terraform plan  2>&1 | tee logs/plan.log
terraform apply -auto-approve 2>&1 | tee logs/apply.log
# When finished and you want to show cleanup:
terraform destroy -auto-approve 2>&1 | tee logs/destroy.log
```

---

## 6) Push to GitHub (`saeedzawarudo-afk/Task3`)

**HTTPS + Personal Access Token (PAT):**

```bash
sudo apt-get install -y git
cd ~/Task3
git init
git config user.name  "saeedzawarudo-afk"
git config user.email "your-email@example.com"
git add .
git commit -m "Task 3: Terraform + Docker (local container)"
git branch -M main
git remote add origin https://github.com/saeedzawarudo-afk/Task3.git
git push -u origin main
```

When asked for a password, use a **GitHub PAT (classic)** with **repo** scope.

**OR SSH keys:**

```bash
ssh-keygen -t ed25519 -C "vm-task3" -N "" -f ~/.ssh/id_ed25519
eval "$(ssh-agent -s)"; ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub  # add this in GitHub → Settings → SSH and GPG keys
git remote set-url origin git@github.com:saeedzawarudo-afk/Task3.git
git push -u origin main
```

---

## 7) Clean up (to stay within free tier)

* Stop VM:
  `az vm deallocate -g rg-task3-linux -n vm-task3-linux`
* Or delete everything:
  `az group delete -n rg-task3-linux --yes --no-wait`

---

## Troubleshooting quickies

* **SSH “Access denied”**

  * Username must be **`azureuser`**.
  * VM → Help → **Reset password** → tab **Reset SSH public key** for user `azureuser`.
  * Networking: inbound **TCP 22** rule exists.

* **Docker permission denied**
  `sudo usermod -aG docker azureuser && newgrp docker` → `docker ps` should work without sudo.

* **Page not loading**

  * Add inbound rule for **8080/TCP**.
  * `docker ps` shows the container running and port mapping.

* **Terraform binary not found**
  Use the **direct binary** install line shown above, then `echo $PATH` and `which terraform`.

---

