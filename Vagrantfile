# -*- mode: ruby -*-
# vi: set ft=ruby :

# This project runs on the libvirt (KVM/QEMU) provider by default.
# Override for a single command, e.g.: VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
ENV['VAGRANT_DEFAULT_PROVIDER'] ||= 'libvirt'

Vagrant.configure("2") do |config|
  # Ubuntu Server 22.04 - note: "ubuntu/jammy64" is VirtualBox-only, this box also
  # ships a libvirt/KVM variant
  config.vm.box = "generic/ubuntu2204"

  # /vagrant must be writable from inside the guests: the Ansible roles download the
  # Hadoop/ZooKeeper tarballs into /vagrant/downloads (shared with the host ./downloads).
  # NFS requires nfs-kernel-server on the host - see README prerequisites.
  config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false
  # Fallback if you do not want to run an NFS server: comment the line above and use
  # config.vm.synced_folder ".", "/vagrant", type: "9p", accessmode: "mapped"

  # Shared libvirt settings for all machines
  config.vm.provider :libvirt do |lv|
    lv.driver = "kvm"
    lv.default_prefix = "hadoop"
    lv.machine_virtual_size = 20
  end
  
  # Common provisioning - minimal setup for Ansible
  $common_script = <<-SCRIPT
    # Update system and install Python for Ansible
    apt-get update
    apt-get install -y python3 python3-pip
    
    # Configure hosts file for all nodes
    cat >> /etc/hosts << 'EOF'
192.168.56.10 master1
192.168.56.11 master2
192.168.56.12 datanode1
192.168.56.13 datanode2
EOF
  SCRIPT
  
  # Master 1 (Active NameNode + ZooKeeper + JournalNode)
  config.vm.define "master1" do |nn1|
    nn1.vm.hostname = "master1"
    nn1.vm.network "private_network", ip: "192.168.56.10"
    
    # Port forwarding for Hadoop web UIs
    nn1.vm.network "forwarded_port", guest: 9870, host: 9870   # NameNode UI
    nn1.vm.network "forwarded_port", guest: 8088, host: 8088   # ResourceManager UI
    nn1.vm.network "forwarded_port", guest: 19888, host: 19888 # JobHistory UI
    nn1.vm.network "forwarded_port", guest: 2181, host: 2181   # ZooKeeper
    
    nn1.vm.provider :libvirt do |lv|
      lv.memory = 2048
      lv.cpus = 2
    end
    
    nn1.vm.provision "shell", inline: $common_script
  end
  
  # Master 2 (Standby NameNode + ZooKeeper + JournalNode)
  config.vm.define "master2" do |nn2|
    nn2.vm.hostname = "master2"
    nn2.vm.network "private_network", ip: "192.168.56.11"
    
    # Port forwarding for standby NameNode UI
    nn2.vm.network "forwarded_port", guest: 9870, host: 9871   # Standby NameNode UI
    nn2.vm.network "forwarded_port", guest: 8088, host: 8089   # Standby ResourceManager UI
    
    nn2.vm.provider :libvirt do |lv|
      lv.memory = 2048
      lv.cpus = 2
    end
    
    nn2.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 1 (DataNode + ZooKeeper + JournalNode)
  config.vm.define "datanode1" do |dn1|
    dn1.vm.hostname = "datanode1"
    dn1.vm.network "private_network", ip: "192.168.56.12"
    
    dn1.vm.provider :libvirt do |lv|
      lv.memory = 2048
      lv.cpus = 1
    end
    
    dn1.vm.provision "shell", inline: $common_script
  end
  
  # DataNode 2 (DataNode only)
  config.vm.define "datanode2" do |dn2|
    dn2.vm.hostname = "datanode2"
    dn2.vm.network "private_network", ip: "192.168.56.13"
    
    dn2.vm.provider :libvirt do |lv|
      lv.memory = 2048
      lv.cpus = 1
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
