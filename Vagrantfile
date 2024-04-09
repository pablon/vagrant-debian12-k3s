# -*- mode: ruby -*-
# vi: set ft=ruby :

VM_BOX      = "debian/bookworm64"
VM_NAME     = "vagrant-k3s"
VM_HOSTNAME = "vagrant-k3s"
VM_RAM      = 4096
VM_CPU      = 2
VM_PARAVIRT = "minimal"
VM_DISK     = "20GB"  # change if needed (default: 20GB)
VM_NET_IP   = "192.168.2.25"

Vagrant.configure("2") do |config|
  config.vm.ignore_box_vagrantfile = true
  config.vm.box = VM_BOX
  config.vm.hostname = VM_HOSTNAME
  config.vm.define VM_NAME
  config.vm.disk :disk, size: VM_DISK, primary: true
  config.vm.provider "virtualbox" do |v|
    v.name = VM_NAME
    v.cpus = VM_CPU
    v.memory = VM_RAM
    v.gui = false
    v.check_guest_additions = false
    v.customize ["modifyvm", :id, "--paravirt-provider", VM_PARAVIRT]
    v.customize ["modifyvm", :id, "--boot1", "disk", "--boot2", "none", "--boot3", "none", "--boot4", "none"]
    v.customize ["modifyvm", :id, "--audio-enabled", "off"]
  end

  config.vm.network "private_network", ip: VM_NET_IP, hostname: true
  # config.vm.network "private_network", type: "dhcp"
  # config.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)", use_dhcp_assigned_default_route: true

  # Enable/disable the default /vagrant share
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # in case you need to forward the ports (if not done globally)
  config.vm.network "forwarded_port", id: "k8s-api", guest: 6443, host: 6443
  config.vm.network "forwarded_port", id: "https", guest: 443, host: 4443
  config.vm.network "forwarded_port", id: "ssh", guest: 22, host: 4422

  config.vm.provision :shell, path: "./scripts/bootstrap.sh"
  config.vm.post_up_message = File.read("./files/README.txt")
end
