# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu Server 22.04
  config.vm.box = "ubuntu/jammy64"
  
  # Common provisioning - minimal setup for Ansible
  $common_script = <<-SCRIPT
    # Update system and install Python for Ansible
    apt-get update
    apt-get install -y python3 python3-pip
    
    # Configure hosts file for all nodes
    cat >> /etc/hosts << 'EOF'
192.168.56.10 master1
192.168.56.12 datanode1
192.168.56.13 datanode2
EOF
  SCRIPT
  
  # Master 1 (Single NameNode + ResourceManager)
  config.vm.define "master1" do |master|
    master.vm.hostname = "master1"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    # Port forwarding for Hadoop web UIs
    master.vm.network "forwarded_port", guest: 9870, host: 9870   # NameNode UI
    master.vm.network "forwarded_port", guest: 8088, host: 8088   # ResourceManager UI
    master.vm.network "forwarded_port", guest: 19888, host: 19888 # JobHistory UI
    
    # Port forwarding for Hive services
    master.vm.network "forwarded_port", guest: 9083, host: 9083   # Hive Metastore
    master.vm.network "forwarded_port", guest: 10000, host: 10000 # HiveServer2
    master.vm.network "forwarded_port", guest: 10002, host: 10002 # HiveServer2 Web UI
    
    master.vm.provider "virtualbox" do |vb|
      vb.name = "master1"
      vb.memory = "2072"
      vb.cpus = 2
    end
    
    master.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 1 (DataNode + NodeManager)
  config.vm.define "datanode1" do |dn1|
    dn1.vm.hostname = "datanode1"
    dn1.vm.network "private_network", ip: "192.168.56.12"
    
    dn1.vm.provider "virtualbox" do |vb|
      vb.name = "datanode1"
      vb.memory = "1048"
      vb.cpus = 1
    end
    
    dn1.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 2 (DataNode + NodeManager)
  config.vm.define "datanode2" do |dn2|
    dn2.vm.hostname = "datanode2"
    dn2.vm.network "private_network", ip: "192.168.56.13"
    
    dn2.vm.provider "virtualbox" do |vb|
      vb.name = "datanode2"
      vb.memory = "1048"
      vb.cpus = 1
    end
    
    dn2.vm.provision "shell", inline: $common_script
    
    # Run Ansible provisioner only after all VMs are up
    dn2.vm.provision "ansible" do |ansible|
      ansible.limit = "all"
      ansible.playbook = "ansible/playbooks/site.yml"
      ansible.inventory_path = "ansible/inventory/hosts.ini"
      ansible.verbose = "v"
      
      # Set ANSIBLE_ROLES_PATH to find roles
      ENV['ANSIBLE_ROLES_PATH'] = File.expand_path('ansible/roles', File.dirname(__FILE__))
      
      # Load variables from group_vars
      ansible.raw_arguments = ["--extra-vars=@ansible/group_vars/all.yml"]
    end
  end
end
