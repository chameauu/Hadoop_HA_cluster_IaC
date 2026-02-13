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
192.168.56.10 namenode1
192.168.56.11 namenode2
192.168.56.12 datanode1
192.168.56.13 datanode2
EOF
  SCRIPT
  
  # NameNode 1 (Active NameNode + ZooKeeper + JournalNode)
  config.vm.define "namenode1" do |nn1|
    nn1.vm.hostname = "namenode1"
    nn1.vm.network "private_network", ip: "192.168.56.10"
    
    # Port forwarding for Hadoop web UIs
    nn1.vm.network "forwarded_port", guest: 9870, host: 9870   # NameNode UI
    nn1.vm.network "forwarded_port", guest: 8088, host: 8088   # ResourceManager UI
    nn1.vm.network "forwarded_port", guest: 19888, host: 19888 # JobHistory UI
    nn1.vm.network "forwarded_port", guest: 2181, host: 2181   # ZooKeeper
    
    nn1.vm.provider "virtualbox" do |vb|
      vb.name = "namenode1"
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    nn1.vm.provision "shell", inline: $common_script
  end
  
  # NameNode 2 (Standby NameNode + ZooKeeper + JournalNode)
  config.vm.define "namenode2" do |nn2|
    nn2.vm.hostname = "namenode2"
    nn2.vm.network "private_network", ip: "192.168.56.11"
    
    # Port forwarding for standby NameNode UI
    nn2.vm.network "forwarded_port", guest: 9870, host: 9871   # Standby NameNode UI
    nn2.vm.network "forwarded_port", guest: 8088, host: 8089   # Standby ResourceManager UI
    
    nn2.vm.provider "virtualbox" do |vb|
      vb.name = "namenode2"
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    nn2.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 1 (DataNode + ZooKeeper + JournalNode)
  config.vm.define "datanode1" do |dn1|
    dn1.vm.hostname = "datanode1"
    dn1.vm.network "private_network", ip: "192.168.56.12"
    
    dn1.vm.provider "virtualbox" do |vb|
      vb.name = "datanode1"
      vb.memory = "2048"
      vb.cpus = 1
    end
    
    dn1.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 2 (DataNode only)
  config.vm.define "datanode2" do |dn2|
    dn2.vm.hostname = "datanode2"
    dn2.vm.network "private_network", ip: "192.168.56.13"
    
    dn2.vm.provider "virtualbox" do |vb|
      vb.name = "datanode2"
      vb.memory = "2048"
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