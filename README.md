# Kubernetes Cluster Setup on AWS with Terraform and Kubeadm

## 📌 Project Overview

This project automates the creation of a **Kubernetes cluster** on **AWS EC2** using **Terraform**.  
It provisions **one master node** and **one worker node**, then configures them into a functioning Kubernetes cluster using **kubeadm**.  
Additionally, some sample YAML files are included to test the cluster after setup.

---

## 🛠️ Prerequisites

- **Terraform**  
- **AWS CLI**  
- **AWS Account** with appropriate permissions  
- **SSH Key Pair**  
- **Ubuntu 22.04 AMI**

---

## 🚀 Installation and Setup

1. **Configure AWS CLI:**

   ```bash
   aws configure
