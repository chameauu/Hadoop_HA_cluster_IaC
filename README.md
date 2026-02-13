# Hadoop HA Cluster - Ansible Edition

A production-ready Hadoop 3.3.6 High Availability cluster managed with Ansible and Vagrant.

## 🚀 Quick Start

```bash
# 1. Create VMs and provision (15-20 min first time)
vagrant up

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
- **VMs**: Vagrant + VirtualBox

## 📖 Prerequisites

Before starting, ensure you have:

- **VirtualBox**: 6.0 or later
- **Vagrant**: 2.2 or later
- **Ansible**: 2.9 or later (on host machine)
- **System Resources**:
  - 8GB RAM minimum (10GB recommended)
  - 6 CPU cores
  - 40GB free disk space

### Installation

**macOS:**
```bash
brew install virtualbox vagrant ansible
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install virtualbox vagrant ansible
```

**Windows:**
- Install VirtualBox from https://www.virtualbox.org/
- Install Vagrant from https://www.vagrantup.com/
- Install Ansible via WSL2 or use Windows Subsystem for Linux

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

# VM Management
vagrant up          # Create and start all VMs
vagrant halt        # Stop all VMs
vagrant destroy -f  # Destroy all VMs
vagrant status      # Check VM status
vagrant ssh namenode1  # SSH into namenode1

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
vagrant up

# Or start one at a time if you have limited resources
vagrant up namenode1
vagrant up namenode2
vagrant up datanode1
vagrant up datanode2
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
3. Initialize HA (format namenode1, bootstrap namenode2, format ZKFC)
4. Start all Hadoop services (NameNodes, DataNodes, ResourceManagers, NodeManagers)

### 4. Verify Cluster

```bash
# Check cluster status
make status

# Or manually check
vagrant ssh namenode1
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
vagrant ssh namenode1
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

## 🔍 Cluster Status

```bash
# Check HA status
vagrant ssh namenode1
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
vagrant ssh namenode1
sudo su - hadoop
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100
```

## 🛠️ Troubleshooting

### VMs won't start
```bash
# Check VirtualBox
vboxmanage list vms

# Check resources (need ~8GB RAM, 6 CPUs)
# Start one at a time
vagrant up namenode1
```

### Services won't start
```bash
# Check logs
vagrant ssh namenode1
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