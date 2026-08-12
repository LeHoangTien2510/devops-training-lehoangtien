#!/usr/bin/env python3
"""
=============================================================================
IaC AIO Backend – REST API Server with SSE Streaming
=============================================================================
API:
  1. GET  /api/iac-vault/{env}/infrastructure  → Đọc biến infra từ Vault
  2. POST /api/iac-generate-tfvars              → Sinh file terraform.tfvars
  3. GET  /api/iac-terraform-stream             → Chạy terraform, stream log realtime qua SSE
  4. GET  /api/health                           → Health check

Cách chạy:
  VAULT_TOKEN=xxx python3 platform/iac-backend/server.py

SSE endpoint:
  GET /api/iac-terraform-stream?env=dev&layers=network,compute&action=plan
  → data: ⏳ terraform init...
  → data: Initializing modules...
  → data: ✅ plan complete
  → event: done
=============================================================================
"""
import json, os, subprocess, sys, threading, time, re
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, unquote
import urllib.request, urllib.error

# ====================================================================
# CONFIG
# ====================================================================
VAULT_ADDR = os.environ.get("VAULT_ADDR", "http://localhost:8200")
VAULT_TOKEN = os.environ.get("VAULT_TOKEN", "")
INFRA_ROOT = os.environ.get("INFRA_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) + "/infra")

if not VAULT_TOKEN:
    cred_file = os.path.join(os.path.dirname(INFRA_ROOT), "infra/vault/vault-credentials.json")
    if os.path.exists(cred_file):
        VAULT_TOKEN = json.load(open(cred_file))["root_token"]

AWS_REGION = "us-east-1"

# ====================================================================
# Vault helpers
# ====================================================================
def vault_read(path):
    url = f"{VAULT_ADDR}/v1/secret/data/{path}"
    req = urllib.request.Request(url)
    req.add_header("X-Vault-Token", VAULT_TOKEN)
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read())["data"]["data"]
    except Exception as e:
        return {"error": str(e)}

# ====================================================================
# TF_VAR_* environment variables generator (NO tfvars file – mentor requirement)
# ====================================================================
def generate_tf_env_vars(layer, vault_data):
    """Trả về dict TF_VAR_* từ Vault data. Không ghi file tfvars nào."""
    env_vars = {}
    common_vars = {
        "TF_VAR_aws_region": vault_data.get("aws_region", AWS_REGION),
        "TF_VAR_aws_profile": vault_data.get("aws_profile", "root-lab-2"),
        "TF_VAR_environment": vault_data.get("environment", "dev"),
    }
    layer_vars = {
        "network": {
            "TF_VAR_vpc_name": vault_data.get("vpc_name", f"eks-lab-vpc-{vault_data.get('environment','dev')}"),
            "TF_VAR_vpc_cidr": vault_data.get("vpc_cidr", "10.0.0.0/16"),
            "TF_VAR_private_subnets": json.dumps(vault_data.get("private_subnets", ["10.0.1.0/24", "10.0.2.0/24"])),
            "TF_VAR_public_subnets": json.dumps(vault_data.get("public_subnets", ["10.0.101.0/24", "10.0.102.0/24"])),
        },
        "compute": {
            "TF_VAR_cluster_name": vault_data.get("cluster_name", "eks-devops-lab"),
            "TF_VAR_node_instance_types": json.dumps(vault_data.get("node_instance_types", ["c7i-flex.large"])),
            "TF_VAR_node_desired_size": str(vault_data.get("node_desired_size", 2)),
            "TF_VAR_node_min_size": str(vault_data.get("node_min_size", 1)),
            "TF_VAR_node_max_size": str(vault_data.get("node_max_size", 3)),
        },
        "jenkins": {
            "TF_VAR_jenkins_instance_type": vault_data.get("jenkins_instance_type", "m7i-flex.large"),
            "TF_VAR_jenkins_root_volume_size": str(vault_data.get("jenkins_root_volume_size", 30)),
            "TF_VAR_key_name": vault_data.get("key_name", "KeyPair-2"),
        },
        "rancher": {
            "TF_VAR_rancher_instance_type": vault_data.get("rancher_instance_type", "c7i-flex.large"),
            "TF_VAR_rancher_root_volume_size": str(vault_data.get("rancher_root_volume_size", 50)),
            "TF_VAR_key_name": vault_data.get("key_name", "KeyPair-2"),
        },
    }
    env_vars.update(common_vars)
    if layer in layer_vars:
        env_vars.update(layer_vars[layer])
    return env_vars

# ====================================================================
# SSE: Stream terraform output line-by-line
# ====================================================================
def sse_send(wfile, data):
    """Gửi 1 sự kiện SSE."""
    wfile.write(f"data: {data}\n\n".encode())
    wfile.flush()

def sse_done(wfile, exit_code, layer):
    """Gửi sự kiện kết thúc."""
    wfile.write(f"event: done\ndata: {{\"layer\":\"{layer}\",\"exit_code\":{exit_code}}}\n\n".encode())
    wfile.flush()

def stream_terraform(wfile, env, layer, action, tf_env_vars=None):
    """Chạy terraform và stream từng dòng output qua SSE. tf_env_vars được inject vào subprocess."""
    layer_dir = os.path.join(INFRA_ROOT, f"envs/{env}/{layer}")
    env_vars = os.environ.copy()
    if tf_env_vars:
        env_vars.update(tf_env_vars)
    
    if not os.path.isdir(layer_dir):
        sse_send(wfile, f"❌ Directory not found: {layer_dir}")
        sse_done(wfile, 1, layer)
        return
    
    try:
        # ─── terraform init ───
        sse_send(wfile, f"━━━ [{layer}] terraform init ━━━")
        proc = subprocess.Popen(
            ["terraform", "init", "-input=false"],
            cwd=layer_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1, env=env_vars
        )
        for line in proc.stdout:
            sse_send(wfile, line.rstrip())
        proc.wait()
        sse_send(wfile, f"✅ init done (exit={proc.returncode})")
        
        # ─── terraform plan ───
        sse_send(wfile, f"")
        sse_send(wfile, f"━━━ [{layer}] terraform plan -out=tfplan ━━━")
        plan_args = ["terraform", "plan", "-input=false", "-out=tfplan"]
        proc = subprocess.Popen(
            plan_args,
            cwd=layer_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1, env=env_vars
        )
        for line in proc.stdout:
            sse_send(wfile, line.rstrip())
        proc.wait()
        plan_ok = (proc.returncode == 0)
        
        if action == "plan":
            status = "✅ Plan completed – no changes needed" if plan_ok else "⚠️ Plan completed with changes"
            sse_send(wfile, status)
            sse_done(wfile, proc.returncode, layer)
            return
        
        # ─── terraform apply ───
        sse_send(wfile, f"")
        sse_send(wfile, f"━━━ [{layer}] terraform apply -auto-approve ━━━")
        apply_args = ["terraform", "apply", "-auto-approve", "-input=false", "tfplan"]
        proc = subprocess.Popen(
            apply_args,
            cwd=layer_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1, env=env_vars
        )
        for line in proc.stdout:
            sse_send(wfile, line.rstrip())
        proc.wait()
        
        status = "✅ Apply completed" if proc.returncode == 0 else f"❌ Apply failed (exit={proc.returncode})"
        sse_send(wfile, status)
        
        # ─── Post-terraform: auto-run Ansible cho jenkins/rancher ───
        if proc.returncode == 0 and layer in ("jenkins", "rancher") and action == "apply":
            sse_send(wfile, "")
            sse_send(wfile, f"━━━ [{layer}] Ansible provisioning ━━━")
            
            ansible_playbook = {
                "jenkins": "jenkins-playbook.yml",
                "rancher": "rancher-playbook.yml",
            }.get(layer)
            
            if ansible_playbook:
                ansible_dir = os.path.join(INFRA_ROOT, "ansible")
                playbook_path = os.path.join(ansible_dir, ansible_playbook)
                
                if os.path.isfile(playbook_path):
                    sse_send(wfile, f"▶ Running: ansible-playbook -i inventory.ini {ansible_playbook}")
                    proc_ansible = subprocess.Popen(
                        ["ansible-playbook", "-i", "inventory.ini", ansible_playbook],
                        cwd=ansible_dir,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                        text=True, bufsize=1, env=env_vars
                    )
                    for line in proc_ansible.stdout:
                        sse_send(wfile, line.rstrip())
                    proc_ansible.wait()
                    status_ansible = "✅ Ansible done" if proc_ansible.returncode == 0 else f"⚠️ Ansible failed (exit={proc_ansible.returncode})"
                    sse_send(wfile, status_ansible)
                else:
                    sse_send(wfile, f"⚠️ Playbook not found: {playbook_path}")
        
        sse_done(wfile, proc.returncode, layer)
        
    except FileNotFoundError:
        sse_send(wfile, "❌ Terraform not found. Please install terraform.")
        sse_done(wfile, 1, layer)
    except Exception as e:
        sse_send(wfile, f"❌ Error: {e}")
        sse_done(wfile, 1, layer)


# ====================================================================
# HTTP SERVER
# ====================================================================
class IacHandler(BaseHTTPRequestHandler):
    
    def _send_json(self, data, status=200):
        body = json.dumps(data, indent=2, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    
    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length > 0:
            return json.loads(self.rfile.read(length))
        return {}
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
    
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)
        
        # ─── GET /api/health ───
        if path == "/api/health":
            self._send_json({
                "status": "ok",
                "vault_addr": VAULT_ADDR,
                "infra_root": INFRA_ROOT,
                "vault_connected": bool(VAULT_TOKEN)
            })
            return
        
        # ─── GET /api/iac-vault/{env}/infrastructure ───
        if path.startswith("/api/iac-vault/"):
            parts = path.split("/")
            vault_path = "/".join(parts[3:])
            data = vault_read(vault_path)
            self._send_json(data)
            return
        
        # ─── GET /api/iac-terraform-stream (SSE) ───
        if path == "/api/iac-terraform-stream":
            env = params.get("env", ["dev"])[0]
            action = params.get("action", ["plan"])[0]
            layers_str = params.get("layers", ["network,compute"])[0]
            layers = [l.strip() for l in layers_str.split(",") if l.strip()]
            
            # 🔒 ENFORCE ORDER: network → compute → jenkins → rancher
            LAYER_ORDER = {"network": 1, "compute": 2, "jenkins": 3, "rancher": 4}
            layers = sorted(layers, key=lambda l: LAYER_ORDER.get(l, 99))
            
            # Thiết lập SSE headers
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            
            wfile = self.wfile
            
            # Đọc vault + gen tfvars trước
            sse_send(wfile, f"🔐 Reading config from Vault: secret/{env}/infrastructure...")
            vault_data = vault_read(f"{env}/infrastructure")
            if "error" in vault_data:
                sse_send(wfile, f"❌ Vault error: {vault_data['error']}")
                sse_done(wfile, 1, "vault")
                return
            sse_send(wfile, f"✅ Loaded: cluster={vault_data.get('cluster_name','?')}, vpc={vault_data.get('vpc_cidr','?')}")
            sse_send(wfile, "")
            
            for layer in layers:
                # Inject TF_VAR_* từ Vault (KHÔNG ghi file tfvars)
                tf_env_vars = generate_tf_env_vars(layer, vault_data)
                sse_send(wfile, f"🔧 Injected {len(tf_env_vars)} TF_VAR_* from Vault for {layer}")
                
                # Chạy terraform streaming
                stream_terraform(wfile, env, layer, action, tf_env_vars)
                sse_send(wfile, "")
            
            sse_send(wfile, f"🏁 ALL DONE – {len(layers)} layer(s) processed")
            wfile.flush()
            # Đóng connection để client biết đã xong
            self.close_connection = True
            return
        
        self._send_json({"error": "Not found"}, 404)
    
    def do_POST(self):
        path = urlparse(self.path).path
        body = self._read_body()
        
        # ─── POST /api/iac-generate-tfvars ───
        if path == "/api/iac-generate-tfvars":
            env = body.get("environment", "dev")
            vault_data = body.get("vault_data", {})
            if not vault_data:
                vault_data = vault_read(f"{env}/infrastructure")
            result = {}
            layers = body.get("layers", ["network", "compute"])
            for layer in layers:
                result[layer] = generate_tfvars(layer, vault_data)
            self._send_json({"tfvars": result, "vault_data": vault_data})
            return
        
        self._send_json({"error": "Not found"}, 404)
    
    def log_message(self, format, *args):
        print(f"[IAC-AIO] {args[0]}")


def main():
    port = int(os.environ.get("PORT", 7070))
    
    print("=" * 50)
    print("  🏗️  IaC AIO Backend Server")
    print("=" * 50)
    print(f"  Vault:   {VAULT_ADDR}")
    print(f"  Infra:   {INFRA_ROOT}")
    print(f"  Port:    {port}")
    print(f"  Token:   {'✅ Set' if VAULT_TOKEN else '❌ MISSING'}")
    print()
    print(f"  API:         http://localhost:{port}/api/health")
    print(f"  Vault:       GET  /api/iac-vault/dev/infrastructure")
    print(f"  Generate:    POST /api/iac-generate-tfvars")
    print(f"  Stream TF:   GET  /api/iac-terraform-stream?env=dev&layers=network&action=plan")
    print("=" * 50)
    
    server = HTTPServer(("0.0.0.0", port), IacHandler)
    print(f"\n✅ Server running at http://localhost:{port}")
    print("   Open UI: file://" + os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/iac-ui/index.html")
    print("   Press Ctrl+C to stop\n")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Shutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
