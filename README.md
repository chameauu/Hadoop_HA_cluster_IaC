# Hadoop HA Cluster - Ansible Edition

A production-ready Hadoop 3.3.6 High Availability cluster managed with Ansible and Vagrant.

## 🚀 Quick Start

```bash
# 1. Create VMs and provision (15-20 min first time)
vagrant up --provider=libvirt

# 2. Start services (2-3 min)
make start

# 3. Access Web UIs
# - NameNode: http://localhost:9870
# - ResourceManager: http://localhost:8088
```

## 📋 What's Inside

### Cluster Architecture
- **4 VMs**: 2 NameNodes + 2 DataNodes
- **HA Setup**: Automatic failover with ZooKeeper
- **YARN HA**: Dual ResourceManagers
- **Resources**: 8GB RAM total, 6 CPUs

### Technology Stack
- **Hadoop**: 3.3.6
- **ZooKeeper**: 3.8.3
- **OS**: Ubuntu 22.04
- **Java**: OpenJDK 8
- **Provisioning**: Ansible 2.9+
- **VMs**: Vagrant + libvirt/KVM (QEMU)

## 📖 Prerequisites

Before starting, ensure you have:

- **KVM / libvirt**: Linux host with hardware virtualization available (`/dev/kvm`)
- **Vagrant**: 2.2 or later
- **vagrant-libvirt plugin**: `vagrant plugin install vagrant-libvirt`
- **Ansible**: 2.9 or later (on host machine)
- **System Resources**:
  - 8GB RAM minimum (10GB recommended)
  - 6 CPU cores
  - 40GB free disk space

### Installation (Debian/Ubuntu host)

```bash
# 1. KVM + libvirt + NFS (used for the /vagrant synced folder) and the
#    build dependencies needed to compile the native parts of the plugin
sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-utils libvirt-daemon-system \
  libvirt-clients nfs-kernel-server libvirt-dev

# 2. Allow your user to talk to libvirtd (log out/in or `newgrp libvirt` afterwards)
sudo usermod -aG libvirt,kvm "$USER"
sudo systemctl enable --now libvirtd

# 3. libvirt needs a storage pool for the VM disks (Debian does not create one)
sudo virsh pool-define-as default dir --target /var/lib/libvirt/images
sudo virsh pool-build default && sudo virsh pool-start default
sudo virsh pool-autostart default

# 4. The libvirt provider itself. Vagrant ships its own embedded Ruby, so the
#    distribution `vagrant-libvirt` package is NOT used - install it as a plugin.
vagrant plugin install vagrant-libvirt

# 5. Ansible plus the collections the roles rely on
sudo apt-get install -y ansible
ansible-galaxy collection install ansible.posix community.crypto
```

**Prefer VirtualBox?** The Vagrantfile uses libvirt by default. Install VirtualBox, then
run `vagrant up --provider=virtualbox` and set a box that has a VirtualBox variant
(for example `ubuntu/jammy64`) in the `Vagrantfile`.

**macOS / Windows:** libvirt is a Linux technology - use VirtualBox there with the
provider override shown above.

## 🎯 Common Commands

```bash
# Cluster Management
make start          # Start all services
make stop           # Stop all services
make restart        # Restart cluster
make status         # Check cluster health
make test           # Run MapReduce test

# Individual Services
make start-zk       # Start ZooKeeper only
make start-jn       # Start JournalNodes only
make init-ha        # Initialize HA (first time only)

# VM Management (libvirt is the default provider, see Vagrantfile)
vagrant up --provider=libvirt   # Create and start all VMs
vagrant halt        # Stop all VMs
vagrant destroy -f  # Destroy all VMs
vagrant status      # Check VM status
vagrant ssh master1 # SSH into master1 (also: master2, datanode1, datanode2)

# Ansible Operations
make provision      # Run Ansible provisioning
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --extra-vars="@ansible/group_vars/all.yml"
```

## 📝 Step-by-Step Setup Guide

### 1. Clone and Setup

```bash
git clone <repository-url>
cd hadoop-cluster
```

### 2. Create VMs

```bash
# Start all VMs (takes 15-20 minutes first time)
vagrant up --provider=libvirt

# Or start one at a time if you have limited resources
vagrant up --provider=libvirt master1
vagrant up --provider=libvirt master2
vagrant up --provider=libvirt datanode1
vagrant up --provider=libvirt datanode2
# Ansible provisioning runs when datanode2 comes up; to re-run it manually:
make provision
```

This will:
- Create 4 Ubuntu VMs
- Install Java, Hadoop, and ZooKeeper
- Configure networking and SSH keys
- Set up Hadoop configuration files

### 3. Start the Cluster

```bash
# Start all services in correct order
make start
```

This runs:
1. Start ZooKeeper cluster (3 nodes)
2. Start JournalNodes (3 nodes)
3. Initialize HA (format master1's NameNode, bootstrap master2, format ZKFC)
4. Start all Hadoop services (NameNodes, DataNodes, ResourceManagers, NodeManagers)

### 4. Verify Cluster

```bash
# Check cluster status
make status

# Or manually check
vagrant ssh master1
sudo su - hadoop
hdfs haadmin -getServiceState nn1  # Should show "active"
hdfs haadmin -getServiceState nn2  # Should show "standby"
hdfs dfsadmin -report              # Should show 2 datanodes
```

### 5. Test the Cluster

```bash
# Run MapReduce Pi calculation
make test

# Or manually
vagrant ssh master1
sudo su - hadoop
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100
```

## 🔧 Manual Service Management

If you prefer to start services manually:

```bash
# 1. Start ZooKeeper
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/start-zookeeper.yml --extra-vars="@ansible/group_vars/all.yml"

# 2. Start JournalNodes
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/start-journalnodes.yml --extra-vars="@ansible/group_vars/all.yml"

# 3. Initialize HA (first time only)
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/initialize-ha.yml --extra-vars="@ansible/group_vars/all.yml"

# 4. Start cluster
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/start-cluster.yml --extra-vars="@ansible/group_vars/all.yml"

# Stop cluster
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/stop-cluster.yml --extra-vars="@ansible/group_vars/all.yml"
```

## 📖 Understanding Hadoop HA

## ⚙️ Configuration

Edit `ansible/group_vars/all.yml`:

```yaml
# Memory settings (MB)
yarn_nodemanager_memory_mb: 1536
mapreduce_am_memory_mb: 512

# Hadoop version
hadoop_version: 3.3.6

# Cluster name
cluster_name: hadoop-cluster
```

### Changing Download Paths

By default, Hadoop and ZooKeeper packages are downloaded to the `downloads/` directory (shared between host and VMs). To change the download location or use pre-downloaded packages:

**Option 1: Use a different local directory**

Edit `ansible/group_vars/all.yml`:

```yaml
# Change the download cache directory
# This directory is shared via Vagrant's synced folder
# Default: /vagrant/downloads/ (maps to ./downloads/ on host)
```

Then update `Vagrantfile` to sync your custom directory:

```ruby
config.vm.synced_folder "./my-custom-downloads", "/vagrant/downloads"
```

**Option 2: Use pre-downloaded packages**

1. Download packages manually:
   ```bash
   mkdir -p downloads
   cd downloads
   wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
   wget https://archive.apache.org/dist/zookeeper/zookeeper-3.8.3/apache-zookeeper-3.8.3-bin.tar.gz
   ```

2. Packages will be detected and used automatically (no re-download)

**Option 3: Change Hadoop/ZooKeeper versions**

Edit `ansible/group_vars/all.yml`:

```yaml
# Hadoop configuration
hadoop_version: 3.3.6  # Change to desired version
hadoop_download_url: "https://archive.apache.org/dist/hadoop/common/hadoop-{{ hadoop_version }}/hadoop-{{ hadoop_version }}.tar.gz"

# ZooKeeper configuration
zookeeper_version: 3.8.3  # Change to desired version
zookeeper_download_url: "https://archive.apache.org/dist/zookeeper/zookeeper-{{ zookeeper_version }}/apache-zookeeper-{{ zookeeper_version }}-bin.tar.gz"
```

**Note**: The `downloads/` directory is gitignored to avoid committing large binary files.

### Apply Configuration Changes

After editing configuration:

```bash
# Re-provision to apply changes
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --extra-vars="@ansible/group_vars/all.yml"

# Or use Vagrant
vagrant provision
```

## 🌐 Web UIs

| Service | URL | Description |
|---------|-----|-------------|
| Active NameNode | http://localhost:9870 | HDFS management |
| Standby NameNode | http://localhost:9871 | Standby NN |
| Active ResourceManager | http://localhost:8088 | YARN management |
| Standby ResourceManager | http://localhost:8089 | Standby RM |
| JobHistory Server | http://localhost:19888 | Job history |

With the libvirt provider the guests are reachable on their private IPs as well, which is
handy when the active/standby roles swap after a failover:

| Node | Address |
|------|---------|
| master1 | http://192.168.56.10:9870 (NameNode), http://192.168.56.10:8088 (ResourceManager) |
| master2 | http://192.168.56.11:9870 (NameNode), http://192.168.56.11:8088 (ResourceManager) |

## 🔍 Cluster Status

```bash
# Check HA status
vagrant ssh master1
sudo su - hadoop
hdfs haadmin -getServiceState nn1  # Should be "active"
hdfs haadmin -getServiceState nn2  # Should be "standby"

# Check HDFS
hdfs dfsadmin -report

# Check YARN
yarn node -list
yarn rmadmin -getServiceState rm1
```

## 🧪 Testing

```bash
# Run MapReduce Pi test
make test

# Or manually
vagrant ssh master1
sudo su - hadoop
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100
```

## 🛠️ Troubleshooting

### VMs won't start
```bash
# Check the libvirt stack
systemctl status libvirtd
virsh list --all        # domains are prefixed, e.g. hadoop_master1
virsh pool-list --all   # the "default" storage pool must be active

# Your user must be in the libvirt and kvm groups
id -nG | tr ' ' '\n' | grep -E '^(libvirt|kvm)$'

# Check resources (need ~8GB RAM, 6 CPUs) and start one at a time
vagrant up --provider=libvirt master1
```

Common errors:
- `The provider 'libvirt' could not be found` → `vagrant plugin install vagrant-libvirt`
- `Could not open a connection to libvirt` / permission denied → group change not active yet (`newgrp libvirt`) or `libvirtd` not started
- `/vagrant` does not mount → NFS server missing: `sudo apt-get install nfs-kernel-server`

### Services won't start
```bash
# Check logs
vagrant ssh master1
tail -f /opt/hadoop/logs/*.log

# Restart services
make restart
```

### Ansible fails
```bash
# Test connectivity
ansible all -i ansible/inventory/hosts.ini -m ping

# Verbose output
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml -vvv
```

## 🎓 Learning Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Hadoop Documentation](https://hadoop.apache.org/docs/r3.3.6/)
- [ZooKeeper Documentation](https://zookeeper.apache.org/doc/r3.8.3/)

## 🔄 Project History

This project was migrated from shell-based provisioning to Ansible:

- **Before**: 1,121 lines of shell scripts in Vagrantfile
- **After**: 80-line Vagrantfile + modular Ansible roles
- **Benefits**: Idempotent, maintainable, production-ready

## 📊 Key Features

✅ **High Availability**: Automatic failover for HDFS and YARN  
✅ **Production-Ready**: Ansible-based infrastructure as code  
✅ **Modular**: Reusable Ansible roles  
✅ **Idempotent**: Safe to run multiple times  
✅ **Easy to Customize**: Centralized configuration  
✅ **Quick Setup**: One command to start  

## 📝 License

This project is provided as-is for educational and development purposes.

## 🎉 Success Indicators

Your cluster is working when:

- ✅ `vagrant status` shows 4 running VMs
- ✅ `make status` shows nn1=active, nn2=standby
- ✅ http://localhost:9870 shows 2 live datanodes
- ✅ `make test` completes successfully

---

**Ready to start?** → Run `vagrant up && make start`