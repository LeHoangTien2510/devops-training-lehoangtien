#!/usr/bin/env python3
"""Sync infrastructure variables to Vault for all environments."""
import json, subprocess, sys

ROOT_TOKEN = json.load(open("infra/vault/vault-credentials.json"))["root_token"]
VAULT_ADDR = "http://localhost:8200"

def vault_put(path, data):
    """Push a secret to Vault KV v2."""
    import urllib.request
    url = f"{VAULT_ADDR}/v1/secret/data/{path}"
    body = json.dumps({"data": data}).encode()
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("X-Vault-Token", ROOT_TOKEN)
    req.add_header("Content-Type", "application/json")
    try:
        resp = urllib.request.urlopen(req)
        return resp.status
    except urllib.error.HTTPError as e:
        return e.code

def vault_get(path):
    """Read a secret from Vault KV v2."""
    import urllib.request
    url = f"{VAULT_ADDR}/v1/secret/data/{path}"
    req = urllib.request.Request(url)
    req.add_header("X-Vault-Token", ROOT_TOKEN)
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read())["data"]["data"]
    except Exception as e:
        return None

# ─── ENVIRONMENT CONFIGS ───
envs = {
    "dev": {
        "aws_profile": "root-lab-2",
        "aws_region": "us-east-1",
        "environment": "dev",
        "cluster_name": "eks-devops-lab",
        "cluster_version": "1.31",
        "vpc_name": "eks-lab-vpc-dev",
        "vpc_cidr": "10.0.0.0/16",
        "azs": ["us-east-1a", "us-east-1b"],
        "private_subnets": ["10.0.1.0/24", "10.0.2.0/24"],
        "public_subnets": ["10.0.101.0/24", "10.0.102.0/24"],
        "node_instance_types": ["c7i-flex.large"],
        "node_desired_size": 2,
        "node_min_size": 1,
        "node_max_size": 3,
        "jenkins_instance_type": "m7i-flex.large",
        "jenkins_root_volume_size": 30,
        "rancher_instance_type": "c7i-flex.large",
        "rancher_root_volume_size": 50,
        "key_name": "KeyPair-2",
        "state_bucket": "terraform-state-devops-lab-tien-v3",
    },
    "stg": {
        "aws_profile": "root-lab-2",
        "aws_region": "us-east-1",
        "environment": "stg",
        "cluster_name": "eks-devops-lab-stg",
        "cluster_version": "1.31",
        "vpc_name": "eks-lab-vpc-stg",
        "vpc_cidr": "10.1.0.0/16",
        "azs": ["us-east-1a", "us-east-1b"],
        "private_subnets": ["10.1.1.0/24", "10.1.2.0/24"],
        "public_subnets": ["10.1.101.0/24", "10.1.102.0/24"],
        "node_instance_types": ["c7i-flex.large"],
        "node_desired_size": 3,
        "node_min_size": 2,
        "node_max_size": 5,
        "jenkins_instance_type": "m7i-flex.large",
        "jenkins_root_volume_size": 50,
        "rancher_instance_type": "c7i-flex.large",
        "rancher_root_volume_size": 50,
        "key_name": "KeyPair-2",
        "state_bucket": "terraform-state-devops-lab-tien-v3",
    },
    "prd": {
        "aws_profile": "root-lab-2",
        "aws_region": "us-east-1",
        "environment": "prd",
        "cluster_name": "eks-devops-lab-prd",
        "cluster_version": "1.31",
        "vpc_name": "eks-lab-vpc-prd",
        "vpc_cidr": "10.2.0.0/16",
        "azs": ["us-east-1a", "us-east-1b"],
        "private_subnets": ["10.2.1.0/24", "10.2.2.0/24"],
        "public_subnets": ["10.2.101.0/24", "10.2.102.0/24"],
        "node_instance_types": ["c6i.large"],
        "node_desired_size": 5,
        "node_min_size": 3,
        "node_max_size": 10,
        "jenkins_instance_type": "m7i-flex.large",
        "jenkins_root_volume_size": 100,
        "rancher_instance_type": "c7i-flex.large",
        "rancher_root_volume_size": 100,
        "key_name": "KeyPair-2",
        "state_bucket": "terraform-state-devops-lab-tien-v3",
    },
}

print("=" * 50)
print("  SYNC INFRA VARS → VAULT")
print("=" * 50)

for env_name, data in envs.items():
    path = f"{env_name}/infrastructure"
    status = vault_put(path, data)
    if status in (200, 204):
        print(f"✅ {env_name}: {data['cluster_name']} (vpc: {data['vpc_cidr']}, nodes: {data['node_desired_size']})")
    else:
        print(f"❌ {env_name}: HTTP {status}")

print()
print("=" * 50)
print("  VERIFY")
print("=" * 50)

for env_name in ["dev", "stg", "prd"]:
    d = vault_get(f"{env_name}/infrastructure")
    if d:
        print(f"  {env_name}: cluster={d['cluster_name']}, vpc={d['vpc_cidr']}, nodes={d['node_desired_size']}")
    else:
        print(f"  {env_name}: ❌ FAILED")

print()
print("✅ DONE – Cấu trúc Vault:")
print("   secret/dev/infrastructure")
print("   secret/stg/infrastructure")
print("   secret/prd/infrastructure")
