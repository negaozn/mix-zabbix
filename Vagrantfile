Vagrant.configure("2") do |config|
    config.vm.box = "bento/ubuntu-22.04"
    config.vm.network "public_network"
    config.vm.network "forwarded_port", guest: 80, host: 8080
    #config.vm.provision :shell, path: "./app/zabbix.sh"
    #config.vm.provision :shell, path: "./app/zabbix2.sh"
    config.vm.provision :shell, path: "./app/docker.sh"
  end