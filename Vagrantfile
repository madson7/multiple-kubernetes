# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false
    config.ssh.private_key_path = ["~/.ssh/id_rsa", "~/.vagrant.d/insecure_private_key"]
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
    config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"
    # rke Server
    config.vm.define "rke", primary: true do |rke|
        rke.vm.box = "generic/ubuntu2004"
        rke.vm.hostname = "rke"
        rke.vm.provider :libvirt do |domain|
            domain.default_prefix = ""
            domain.cpus = "4"
            domain.memory = "8192"
        end
    end
end