class Homestead
  def Homestead.configure(config, settings)
    # Configure The Box
    config.vm.box = "npmweb/workstead"
    config.vm.hostname = "dvmcweb55-local2"
    config.vm.box_version = ">= 0.1.1"
    config.vm.box_check_update = true

    # Configure A Private Network IP
    config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.name = "php55-dev"
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8000
    config.vm.network "forwarded_port", guest: 8000, host: 8008
    config.vm.network "forwarded_port", guest: 3306, host: 33060
    config.vm.network "forwarded_port", guest: 5432, host: 54320
    config.vm.network "forwarded_port", guest: 11300, host: 11333

    # Configure The Public Key For SSH Access
    config.vm.provision "shell" do |s|
      s.inline = "echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
      s.args = [File.read(File.expand_path(settings["authorize"]))]
    end

    # Copy The SSH Private Keys To The Box
    settings["keys"].each do |key|
      config.vm.provision "shell" do |s|
        s.privileged = false
        s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
        s.args = [File.read(File.expand_path(key)), key.split('/').last]
      end
    end

    # Copy The ssh Config
    config.vm.provision "shell" do |s|
      s.privileged = false
      s.inline = "echo \"$1\" > /home/vagrant/.ssh/config && chmod 600 /home/vagrant/.ssh/config"
      s.args = [File.read(File.expand_path(settings["config"]))]
    end

    # Copy The Bash Aliases
    #config.vm.provision "shell" do |s|
    #  s.inline = "cp /vagrant/aliases /home/vagrant/.aliases"
    #end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil, :mount_options => folder["options"] ||= nil, :owner => folder["owner"] ||= nil, :group => folder["group"] ||= nil
    end

    # Remove Previously Configured Apache Sites
    config.vm.provision "shell" do |s|
      s.inline = "rm -fv /etc/httpd/conf.d/50-*.conf 2> /dev/null"
    end

    # Install All The Configured Apache Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
          s.inline = "bash /vagrant/scripts/serve.sh $1 $2 \"$3\" \"$4\" \"$5\""
          s.args = [site["map"], site["to"], site["alias"] ||= "", site["alias_to"] ||= "", site["phperr"] ||= ""]
      end
    end

    # Create all configured databases
    settings["dbs"].each do |db|
      config.vm.provision "shell" do |s|
          s.inline = "bash /vagrant/scripts/mysql.sh $1 $2 $3"
          s.args = [db["database"], db["username"], db["password"]]
      end
    end

  end
end
