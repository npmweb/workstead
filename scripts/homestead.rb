class Homestead
  def Homestead.configure(config, settings)
    # Configure The Box
    config.vm.box = "npmweb/workstead"
    config.vm.hostname = "dvmcweb55-local2"
    config.vm.box_version = ">= 0.1.1"
    config.vm.box_check_update = true
    # config.vm.box_url = "http://test.npmweb.org/downloads/npm-workstead-0.1.6.box"

    # Configure A Private Network IP
    config.vm.network "private_network", ip: settings["ip"] ||= "192.168.10.10", auto_config: true

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.name = settings["boxname"]
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8000
    config.vm.network "forwarded_port", guest: 8000, host: 8008
    config.vm.network "forwarded_port", guest: 3306, host: 33060
    config.vm.network "forwarded_port", guest: 5432, host: 54320
    config.vm.network "forwarded_port", guest: 11300, host: 11333

    config.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"

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
    config.vm.provision "shell" do |s|
      s.inline = "cp /vagrant/aliases /home/vagrant/.aliases"
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil, :mount_options => folder["options"] ||= nil, :owner => folder["owner"] ||= nil, :group => folder["group"] ||= nil
    end

    # Install All The Configured Apache Sites
    settings["sites"].each do |site|
      # Process the incoming hashes to a string for passing to the shell script
      if site['aliases']
        aliases = []
        site['aliases'].each do |a|
          aliases << "#{a["name"]},#{a["to"]}"
        end
        concat_aliases = aliases.join(':')
      end

      config.vm.provision "shell" do |s|
          s.inline = "bash /vagrant/scripts/serve.sh $1 $2 \"$3\" \"$4\""
          s.args = [site["map"], site["to"], site["phperr"] ||= "", concat_aliases ||= ""]
      end
    end

    # Create all configured databases
    settings["dbs"].each do |db|
      config.vm.provision "shell" do |s|
          s.inline = "bash /vagrant/scripts/mysql.sh $1 $2 $3"
          s.args = [db["database"], db["username"], db["password"]]
      end
    end

    # restart the things that need restarting
    config.vm.provision "shell" do |s|
      s.inline = "sudo service httpd restart"
    end
  end
end
