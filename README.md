# Caladan - DevOps Work Sample Submission

This repository contains the submission for the Senior Platform Engineer technical challenge. The project provisions two cloud servers and deploys a simple application to measure and expose the network latency between them.

---

## Technology Choices & Rationale

* **Cloud Provider: AWS**
    * **Rationale:** Chosen as it was the preferred provider in the assignment. AWS offers a robust and mature ecosystem for building scalable and secure infrastructure.

* **Infrastructure as Code: Terraform**
    * **Rationale:** Terraform is the industry standard for cloud-agnostic IaC. It allows for declarative, version-controlled, and repeatable infrastructure, which is crucial for preventing configuration drift and enabling automation.

* **Application: Python & Flask**
    * **Rationale:** Python was chosen for its rapid development speed and excellent libraries. `Flask` is a lightweight web framework, perfect for creating a simple, single-purpose API endpoint as required. The `ping3` library was used for a clean, cross-platform way to perform ICMP pings without wrapping system commands.

* **Containerization & Deployment: Docker & `user_data` Script**
    * **Rationale:** **Docker** was chosen to containerize the application. This encapsulates the app and its dependencies, ensuring it runs consistently anywhere. The deployment is fully automated using an EC2 `user_data` script, which installs Docker, clones this repository, and runs the container on boot. This demonstrates a complete, end-to-end, hands-off deployment process.

---

## How to Run the Project

**Prerequisites:**
* An AWS account with credentials configured.
* Terraform installed locally.

**Steps:**

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/vlu-lantran/caladan-assignments.git
    cd caladan-assignments/terraform
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Provision the infrastructure:**
    ```bash
    terraform apply --auto-approve
    ```
    This process will take a few minutes. Once complete, it will output the public IP address of the `metrics-server`.

---

## How to Access the Latency Metrics

Once `terraform apply` is finished, use the output IP address to access the metrics endpoint via `curl` or your browser:

```bash
# Get the IP from Terraform output
METRICS_SERVER_IP=$(terraform output -raw metrics_server_public_ip)

# Query the endpoint
curl http://${METRICS_SERVER_IP}:5000/metrics
```