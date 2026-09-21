.PHONY: help setup start stop restart status clean destroy provision format-namenode

INVENTORY := ansible/inventory/hosts.ini
PLAYBOOK_DIR := ansible/playbooks

help:
	@echo "Hadoop 3-Node Cluster - Ansible Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup          - Create VMs and provision with Ansible"
	@echo "  make provision      - Run Ansible provisioning only"
	@echo "  make format-namenode - Format NameNode (first time only)"
	@echo "  make start          - Start all cluster services"
	@echo "  make stop           - Stop all cluster services"
	@echo "  make restart        - Restart all cluster services"
	@echo "  make status         - Check cluster status"
	@echo "  make clean          - Stop cluster and clean data"
	@echo "  make destroy        - Destroy all VMs"
	@echo ""
	@echo "Hive commands:"
	@echo "  make install-hive   - Install Hive on master1"
	@echo "  make init-hive      - Initialize Hive (HDFS dirs, Tez upload, schema)"
	@echo "  make start-hive     - Start Hive Metastore and HiveServer2"
	@echo "  make stop-hive      - Stop Hive services"

setup:
	@echo "Creating VMs and provisioning with Ansible..."
	vagrant up

provision:
	@echo "Running Ansible provisioning..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/site.yml --extra-vars="@ansible/group_vars/all.yml"

format-namenode:
	@echo "Formatting NameNode (WARNING: This will erase all HDFS data)..."
	@vagrant ssh master1 -c 'sudo su - hadoop -c "/opt/hadoop/bin/hdfs namenode -format -force"'

start:
	@echo "Starting Hadoop cluster..."
	@ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/start-cluster.yml --extra-vars="@ansible/group_vars/all.yml"

stop:
	@echo "Stopping Hadoop cluster..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/stop-cluster.yml --extra-vars="@ansible/group_vars/all.yml"

restart: stop
	@sleep 5
	@make start

status:
	@echo "Checking cluster status..."
	@vagrant ssh master1 -c 'sudo su - hadoop -c "hdfs dfsadmin -report"'
	@vagrant ssh master1 -c 'sudo su - hadoop -c "yarn node -list"'

clean:
	@make stop
	@echo "Cleaning data directories..."
	@vagrant ssh master1 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/tmp/*'
	@vagrant ssh datanode1 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/tmp/*'
	@vagrant ssh datanode2 -c 'sudo rm -rf /opt/hadoop/hdfs/* /opt/hadoop/tmp/*'

destroy:
	@echo "Destroying all VMs..."
	vagrant destroy -f

# Quick test
test:
	@echo "Running MapReduce Pi test..."
	@vagrant ssh master1 -c 'sudo su - hadoop -c "hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100"'

# Hive commands
install-hive:
	@echo "Installing Hive..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install-hive.yml --extra-vars="@ansible/group_vars/all.yml"

init-hive:
	@echo "Initializing Hive..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/initialize-hive.yml --extra-vars="@ansible/group_vars/all.yml"

start-hive:
	@echo "Starting Hive services..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/start-hive.yml --extra-vars="@ansible/group_vars/all.yml"

stop-hive:
	@echo "Stopping Hive services..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/stop-hive.yml --extra-vars="@ansible/group_vars/all.yml"
