.PHONY: help setup start stop restart status clean destroy provision

INVENTORY := ansible/inventory/hosts.ini
PLAYBOOK_DIR := ansible/playbooks

help:
	@echo "Hadoop HA Cluster - Ansible Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup       - Create VMs and provision with Ansible"
	@echo "  make provision   - Run Ansible provisioning only"
	@echo "  make start       - Start all cluster services"
	@echo "  make stop        - Stop all cluster services"
	@echo "  make restart     - Restart all cluster services"
	@echo "  make status      - Check cluster status"
	@echo "  make clean       - Stop cluster and clean data"
	@echo "  make destroy     - Destroy all VMs"
	@echo ""
	@echo "Individual service commands:"
	@echo "  make start-zk    - Start ZooKeeper only"
	@echo "  make start-jn    - Start JournalNodes only"
	@echo "  make init-ha     - Initialize HA (first time only)"

setup:
	@echo "Creating VMs and provisioning with Ansible..."
	vagrant up

provision:
	@echo "Running Ansible provisioning..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/site.yml --extra-vars="@ansible/group_vars/all.yml"

start-zk:
	@echo "Starting ZooKeeper cluster..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/start-zookeeper.yml --extra-vars="@ansible/group_vars/all.yml"

start-jn:
	@echo "Starting JournalNodes..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/start-journalnodes.yml --extra-vars="@ansible/group_vars/all.yml"

init-ha:
	@echo "Initializing HA cluster..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/initialize-ha.yml --extra-vars="@ansible/group_vars/all.yml"

start:
	@echo "Starting Hadoop HA cluster..."
	@make start-zk
	@sleep 5
	@make start-jn
	@sleep 5
	@make init-ha
	@sleep 5
	@ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/start-cluster.yml --extra-vars="@ansible/group_vars/all.yml"

stop:
	@echo "Stopping Hadoop HA cluster..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/stop-cluster.yml --extra-vars="@ansible/group_vars/all.yml"

restart: stop
	@sleep 5
	@make start

status:
	@echo "Checking cluster status..."
	@vagrant ssh namenode1 -c 'sudo su - hadoop -c "hdfs haadmin -getServiceState nn1"'
	@vagrant ssh namenode1 -c 'sudo su - hadoop -c "hdfs haadmin -getServiceState nn2"'
	@vagrant ssh namenode1 -c 'sudo su - hadoop -c "hdfs dfsadmin -report"'

clean:
	@make stop
	@echo "Cleaning data directories..."
	@vagrant ssh namenode1 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/journal/* /opt/hadoop/tmp/*'
	@vagrant ssh namenode2 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/journal/* /opt/hadoop/tmp/*'
	@vagrant ssh datanode1 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/journal/* /opt/hadoop/tmp/*'
	@vagrant ssh datanode2 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/tmp/*'

destroy:
	@echo "Destroying all VMs..."
	vagrant destroy -f

# Quick test
test:
	@echo "Running MapReduce Pi test..."
	@vagrant ssh namenode1 -c 'sudo su - hadoop -c "hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100"'
