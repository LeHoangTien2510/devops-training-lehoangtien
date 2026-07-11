# Bài 3: Ansible - Các lỗi đã gặp và cách sửa

## Môi trường
- **Ansible controller**: Ubuntu 22.04 WSL, Ansible 2.10.8 (cài từ apt)
- **Target VMs**: Ubuntu 20.04 (focal) trên VMware
  - VM1: 192.168.183.102 (monitoring server)
  - VM2: 192.168.183.103 (target node)
- **User**: reatimo / hoangtien123

---

## 1. Ansible chưa được cài trên controller
**Lỗi**: `ansible: command not found`
**Sửa**: `sudo apt install -y ansible`

---

## 2. Thiếu sshpass để SSH bằng password
**Lỗi**: `sshpass: command not found`
**Sửa**: `sudo apt install -y sshpass`

---

## 3. Thiếu ansible_become_password
**Lỗi**: `Missing sudo password`
**Sửa**: Thêm vào `inventory/hosts.ini`:
```ini
[all:vars]
ansible_become_password=hoangtien123
```

---

## 4. CDROM repository chặn apt update
**Lỗi**: `The repository 'file:/cdrom focal Release' no longer has a Release file`
**Sửa**: Thêm task `lineinfile` vào role docker, regex: `^deb .*cdrom`
```yaml
- name: Vô hiệu hóa CDROM repository
  lineinfile:
    path: /etc/apt/sources.list
    regexp: '^deb .*cdrom'
    state: absent
```
> **Bài học**: Trên VM tạo từ VMware template, CDROM repo thường được bật. Cần regex linh hoạt vì định dạng có thể là `deb cdrom:...` hoặc `deb [check-date=no] file:///cdrom ...`

---

## 5. Docker repository cũ gây xung đột Signed-By
**Lỗi**: `Conflicting values set for option Signed-By regarding source https://download.docker.com/...`
**Sửa**: Dọn dẹp file Docker repo cũ trước khi thêm mới:
```yaml
- name: Dọn dẹp Docker repository cũ
  shell: |
    rm -f /etc/apt/sources.list.d/docker* \
          /etc/apt/sources.list.d/download_docker* \
          /usr/share/keyrings/docker-archive-keyring.gpg
  args:
    warn: false
```

---

## 6. Thứ tự task trong role docker
**Lỗi**: Task dọn dẹp Docker repo cũ chạy SAU `apt update` → apt update vẫn lỗi
**Sửa**: Sắp xếp lại thứ tự:
1. Xóa CDROM repo
2. Dọn Docker repo cũ
3. `apt update`
4. Cài gói phụ thuộc
5. Thêm Docker GPG key + repo mới
6. Cài Docker Engine

---

## 7. docker_compose_v2 module không tồn tại
**Lỗi**: `couldn't resolve module/action 'docker_compose_v2'`
**Sửa**: `ansible-galaxy collection install community.docker`

---

## 8. docker_compose_v2 không tương thích Ansible 2.10.8
**Lỗi**: `Could not find imported module support code for ... docker_compose_v2`
**Nguyên nhân**: community.docker 5.x yêu cầu Ansible >= 2.14
**Sửa**: Thay vì dùng module, dùng `shell` module gọi Docker Compose CLI:
```yaml
- name: Khởi động Prometheus
  shell:
    cmd: docker compose up -d
    chdir: "{{ monitoring_base_dir }}/prometheus"
  register: result
  changed_when: "'up-to-date' not in result.stdout and 'Started' in result.stdout"
```
> **Bài học**: Ansible cài từ apt trên Ubuntu 22.04 là phiên bản 2.10.8 (cũ). Nên cài từ pip để có phiên bản mới hơn: `pip install ansible`

---

## 9. Biến group_vars không load được khi dùng explicit vars:
**Lỗi**: `'node_exporter_version' is undefined` (trong khi `ansible -m debug` thấy có)
**Nguyên nhân**: Khi play dùng `vars:` explicit, group_vars từ `all` không merge vào
**Sửa**: Khai báo biến trực tiếp trong `vars:` của từng play:
```yaml
- name: Cài Node Exporter
  hosts: targets
  become: yes
  vars:
    node_exporter_version: "1.8.1"
  roles:
    - node_exporter
```

---

## 10. Thiếu unzip trên target VM
**Lỗi**: `Failed to find handler for "/tmp/promtail.zip". Command "unzip" not found`
**Sửa**: Thêm task cài unzip vào role promtail:
```yaml
- name: Cài unzip
  apt:
    name: unzip
    state: present
```

---

## 11. Docker permission denied cho user thường
**Lỗi**: `permission denied while trying to connect to the Docker daemon socket`
**Nguyên nhân**: User `reatimo` được thêm vào group `docker` nhưng session SSH hiện tại chưa nhận group mới
**Sửa**: Đổi `become: no` → `become: yes` cho các play chạy Docker Compose (Prometheus, Grafana, Loki)

---

## 12. Biến vault (grafana_admin_password) không load
**Lỗi**: `'grafana_admin_user' is undefined`
**Nguyên nhân**: Kết hợp giữa `vars:` explicit và vault encrypted
**Sửa**: 
1. Thêm `grafana_admin_user` trực tiếp vào play vars
2. Thêm `vars_files: ../group_vars/all/vault.yml` để load biến từ vault

---

## 13. vars_files path sai
**Lỗi**: `vars file group_vars/all/vault.yml was not found`
**Nguyên nhân**: `vars_files` tính relative từ vị trí file playbook (`playbooks/monitoring.yml`)
**Sửa**: Đổi thành `../group_vars/all/vault.yml`

---

## Tổng kết bài học

| Vấn đề | Giải pháp |
|--------|-----------|
| Ansible 2.10 quá cũ | Nên dùng pip install ansible để có >= 2.14 |
| VM từ VMware template | Luôn check & disable CDROM repo |
| Docker repo cũ | Dọn dẹp triệt để trước khi cài mới |
| community.docker module | Không tương thích Ansible cũ → dùng shell CLI |
| group_vars + explicit vars | Không merge được → khai báo đủ trong vars |
| Docker permission | Cần become: yes hoặc reset SSH session |
| vars_files path | Luôn tính relative từ playbook file |
