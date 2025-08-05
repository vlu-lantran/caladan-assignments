<!-- TOC --><a name="caladan-devops-work-sample-submission"></a>
# Caladan - DevOps Work Sample Submission

This repository contains the submission for the Senior Platform Engineer technical challenge. The project provisions two cloud servers and deploys a simple application to measure and expose the network latency between them.

---

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Caladan - DevOps Work Sample Submission](#caladan-devops-work-sample-submission)
   * [Technology Choices & Rationale](#technology-choices-rationale)
   * [How to run the Project](#how-to-run-the-project)
   * [How to access the Latency Metrics](#how-to-access-the-latency-metrics)
   * [How to clean up the infrastructure](#how-to-clean-up-the-infrastructure)
   * [Optional Reflection & Production Considerations](#optional-reflection-production-considerations)

<!-- TOC end -->

<!-- TOC --><a name="technology-choices-rationale"></a>
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

<!-- TOC --><a name="how-to-run-the-project"></a>
## How to run the Project

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

<!-- TOC --><a name="how-to-access-the-latency-metrics"></a>
## How to access the Latency Metrics

Once `terraform apply` is finished, use the output IP address to access the metrics endpoint via `curl` or your browser:

```bash
# Get the IP from Terraform output
METRICS_SERVER_IP=$(terraform output -raw metrics_server_public_ip)

# Query the endpoint
curl http://${METRICS_SERVER_IP}:5000/metrics
```

**Example Output:**
```
{"latency_ms":0.34,"status":"ok"}
```

---

<!-- TOC --><a name="how-to-clean-up-the-infrastructure"></a>
## How to clean up the infrastructure

1.  **Navigate to terraform directory:**
    ```bash
    cd caladan-assignments/terraform
    ```

2.  **Execute clean up command:**
    ```bash
    terraform destroy
    ```

3.  **Confirm the Destruction:**
* After displaying the plan, Terraform will ask for a final confirmation to proceed.
    ```
    Do you really want to destroy all resources?
    Terraform will destroy all your managed infrastructure...
    There is no undo. Only 'yes' will be accepted to confirm.

    Enter a value:
    ```

    You must type exactly `yes` and press `Enter`.

---

<!-- TOC --><a name="optional-reflection-production-considerations"></a>
## Optional Reflection & Production Considerations

1.  **Observed Latency Insights**

* During my testing, I observed an average round-trip latency of 3ms on local network. Moving to AWS, this latency ranges from 0.23ms to only 0.3ms. This is indicates that Terraform, by default, placed both EC2 instances within the same Availability Zone (AZ), minimizing physical distance, and as a matter of facts, the AWS networking infrastructure is far better than my home equipments. The consistency of the measurement also indicates a stable network environment provided by the AWS infrastructure.

2.  **What I Would Do Differently in a Production Setup**

* High Availability: I would provision servers across multiple Availability Zones within the same VPC. This would slightly increase latency but would ensure the system remains operational if one entire data center fails.

* Monitoring & Alerting: In production, I would integrate it with a proper monitoring system like Prometheus or Dynatrace. Both of them could be configured to automatically collect the latency to the target server. The data would be stored in their databases and visualized (using Grafana in Prometheus cases). I would set up alerts to trigger if latency consistently exceeds a critical threshold (e.g., >10ms for 5 minutes).

* Security: The current setup allows SSH from anywhere (0.0.0.0/0), which is insecure. In production, I would lock this down to a specific IP range. 

* Repository Separation: I would split the application and infrastructure code into two separate Git repositories to enable independent lifecycles.

* Container Orchestration: Instead of running Docker directly on an EC2 instance, I would deploy the service to Amazon EKS (Kubernetes). This provides critical production features like self-healing, automated scaling, and simplified service discovery.

* CI/CD Pipeline: I would build a full CI/CD pipeline using a tool like GitHub Actions / Jenkins. A push to the application repository would trigger the pipeline to build and test a new Docker image, push it to Amazon ECR, and then update the Kubernetes deployment using a tool like Helm or ArgoCD to perform a zero-downtime rolling update.
