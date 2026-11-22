require "open3"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  red_web = "asir-balanceador-web"
  red_db = "asir-balanceador-db"
  ip_host = ENV.fetch("BALANCEADOR_IP_HOST", "192.168.1.137")
  dominio = ENV.fetch("BALANCEADOR_DOMINIO", "balanceadorweb.ddns.net")
  unless dominio.match?(/\A[a-zA-Z0-9][a-zA-Z0-9.-]*\z/)
    abort "BALANCEADOR_DOMINIO debe contener solo el nombre DNS."
  end

  # Puerto SSH local que Vagrant usa al preparar las maquinas internas.
  config.vm.network "forwarded_port", guest: 22, host: 2222,
    host_ip: "127.0.0.1", id: "ssh", auto_correct: true

  # El SSH de las máquinas privadas pasa por el balanceador después de instalar.
  archivo_ssh = File.join(__dir__, "ssh_config")
  salto_ssh = %(ssh.exe -F "#{archivo_ssh}" -o BatchMode=yes -W %h:%p)

  config.vm.define "mysql" do |mysql|
    # La marca se guarda después de instalar los servicios y aplicar el cortafuegos.
    marca = ".vagrant/machines/mysql/virtualbox/red-privada"
    instalado = File.file?(File.join(__dir__, marca))

    if instalado
      mysql.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", disabled: true
      mysql.ssh.host = "192.168.58.20"
      mysql.ssh.port = 22
      mysql.ssh.proxy_command = "#{salto_ssh} web1"
    end

    mysql.vm.hostname = "AlexanderHuamanMysql"
    mysql.vm.network "private_network", ip: "192.168.58.20",
      virtualbox__intnet: red_db
    mysql.vm.provision "shell", path: "scripts/mysql.sh" unless instalado
    mysql.vm.provision "firewall", type: "shell", path: "scripts/firewall.sh", args: ["mysql"]
    unless instalado
      mysql.vm.provision "finalizar", type: "shell", inline: "touch /vagrant/#{marca}"
    end

    mysql.vm.provider "virtualbox" do |vb|
      vb.name = "ASIR-Balanceador-MySQL"
      vb.memory = 1024
      vb.customize ["modifyvm", :id, "--nic1", "null", "--cable-connected1", "off"] if instalado
    end
  end

  config.vm.define "web1" do |web1|
    # La marca se guarda después de instalar los servicios y aplicar el cortafuegos.
    marca = ".vagrant/machines/web1/virtualbox/red-privada"
    instalado = File.file?(File.join(__dir__, marca))

    if instalado
      web1.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", disabled: true
      web1.ssh.host = "192.168.57.11"
      web1.ssh.port = 22
      web1.ssh.proxy_command = "#{salto_ssh} balanceador"
    end

    web1.vm.hostname = "AlexanderHuamanWeb1"
    web1.vm.network "private_network", ip: "192.168.57.11",
      virtualbox__intnet: red_web
    web1.vm.network "private_network", ip: "192.168.58.11",
      virtualbox__intnet: red_db
    web1.vm.provision "shell", path: "scripts/apache.sh", args: ["web1"] unless instalado
    web1.vm.provision "firewall", type: "shell", path: "scripts/firewall.sh", args: ["web1"]
    unless instalado
      web1.vm.provision "finalizar", type: "shell", inline: "touch /vagrant/#{marca}"
    end

    web1.vm.provider "virtualbox" do |vb|
      vb.name = "ASIR-Balanceador-Web1"
      vb.memory = 640
      vb.customize ["modifyvm", :id, "--nic1", "null", "--cable-connected1", "off"] if instalado
    end
  end

  config.vm.define "web2" do |web2|
    # La marca se guarda después de instalar los servicios y aplicar el cortafuegos.
    marca = ".vagrant/machines/web2/virtualbox/red-privada"
    instalado = File.file?(File.join(__dir__, marca))

    if instalado
      web2.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", disabled: true
      web2.ssh.host = "192.168.57.12"
      web2.ssh.port = 22
      web2.ssh.proxy_command = "#{salto_ssh} balanceador"
    end

    web2.vm.hostname = "AlexanderHuamanWeb2"
    web2.vm.network "private_network", ip: "192.168.57.12",
      virtualbox__intnet: red_web
    web2.vm.network "private_network", ip: "192.168.58.12",
      virtualbox__intnet: red_db
    web2.vm.provision "shell", path: "scripts/apache.sh", args: ["web2"] unless instalado
    web2.vm.provision "firewall", type: "shell", path: "scripts/firewall.sh", args: ["web2"]
    unless instalado
      web2.vm.provision "finalizar", type: "shell", inline: "touch /vagrant/#{marca}"
    end

    web2.vm.provider "virtualbox" do |vb|
      vb.name = "ASIR-Balanceador-Web2"
      vb.memory = 640
      vb.customize ["modifyvm", :id, "--nic1", "null", "--cable-connected1", "off"] if instalado
    end
  end

  config.vm.define "balanceador" do |balanceador|
    balanceador.vm.hostname = "AlexanderHuamanBalanceador"
    balanceador.vm.network "private_network", ip: "192.168.57.10",
      virtualbox__intnet: red_web

    # Entro por SSH desde Windows y uso el balanceador para llegar a las otras VM.
    balanceador.vm.network "forwarded_port", guest: 22, host: 2229,
      host_ip: "127.0.0.1", id: "ssh", auto_correct: false
    balanceador.vm.network "forwarded_port", guest: 80, host: 8080,
      host_ip: ip_host, id: "http"
    balanceador.vm.network "forwarded_port", guest: 443, host: 8443,
      host_ip: ip_host, id: "https"

    balanceador.vm.provision "shell", path: "scripts/balanceador.sh", args: [dominio]
    balanceador.vm.provision "firewall", type: "shell", path: "scripts/firewall.sh", args: ["balanceador"]

    balanceador.vm.provider "virtualbox" do |vb|
      vb.name = "ASIR-Balanceador-Apache"
      vb.memory = 512
    end
  end

  # Limpio los reenvíos guardados antes de que Vagrant los vuelva a crear.
  config.trigger.before :up do |trigger|
    trigger.ruby do |_env, machine|
      next unless machine.id && machine.state.id == :poweroff

      info, estado = Open3.capture2("VBoxManage.exe", "showvminfo", machine.id, "--machinereadable")
      raise "No he podido consultar #{machine.name}." unless estado.success?
      next unless info.lines.map(&:chomp).include?('nic1="nat"')

      info.each_line do |linea|
        reenvio = linea[/^Forwarding\(\d+\)="(ssh|http|https),/, 1]
        next unless reenvio

        unless system("VBoxManage.exe", "modifyvm", machine.id, "--natpf1", "delete", reenvio)
          raise "No he podido retirar el reenvío #{reenvio} de #{machine.name}."
        end
      end
    end
  end

  # Desconecto el NAT cuando la máquina privada ha terminado de instalarse.
  config.trigger.after [:up, :reload, :provision, :resume] do |trigger|
    trigger.only_on = ["mysql", "web1", "web2"]

    trigger.ruby do |_env, machine|
      next unless machine.data_dir.join("red-privada").file?
      next unless machine.id && machine.state.id == :running

      info, estado = Open3.capture2("VBoxManage.exe", "showvminfo", machine.id, "--machinereadable")
      raise "No he podido consultar #{machine.name}." unless estado.success?
      next unless info.lines.map(&:chomp).include?('nic1="nat"')

      unless system("VBoxManage.exe", "controlvm", machine.id, "setlinkstate1", "off")
        raise "No he podido desconectar el cable de #{machine.name}."
      end
      unless system("VBoxManage.exe", "controlvm", machine.id, "nic1", "null")
        raise "No he podido quitar el NAT de #{machine.name}."
      end
    end
  end
end
