Vagrant.configure("2") do |config|
  # Base box settings
  BOX_NAME = "ubuntu/jammy64"   # Latest Ubuntu LTS
  BOX_MEMORY = 1024
  BOX_CPUS = 1

  # -------- Server (Controller) --------
  config.vm.define "rouarrakS" do |server|
    server.vm.box = BOX_NAME
    server.vm.hostname = "rouarrakS"
    server.vm.network "private_network", ip: "192.168.56.110"

    server.vm.provider "virtualbox" do |v|
      v.name = "rouarrakS"
      v.memory = BOX_MEMORY
      v.cpus = BOX_CPUS
    end

    server.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y curl sshpass git vim

      # Disable swap
      sudo swapoff -a
      sudo sed -i '/ swap / s/^/#/' /etc/fstab

      # Install K3s server
      curl -sfL https://get.k3s.io | sh -

      # Install kubectl
      sudo apt-get install -y kubectl

      # Allow passwordless SSH within Vagrant network
      mkdir -p ~/.ssh
      ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
      cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/authorized_keys
    SHELL
  end

  # -------- Worker (Agent) --------
  config.vm.define "rouarrakSW" do |worker|
    worker.vm.box = BOX_NAME
    worker.vm.hostname = "rouarrakSW"
    worker.vm.network "private_network", ip: "192.168.56.111"

    worker.vm.provider "virtualbox" do |v|
      v.name = "rouarrakSW"
      v.memory = BOX_MEMORY
      v.cpus = BOX_CPUS
    end

    worker.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y curl sshpass git vim

      # Disable swap
      sudo swapoff -a
      sudo sed -i '/ swap / s/^/#/' /etc/fstab

      # Get K3s token from server
      SERVER_IP="192.168.56.110"
      TOKEN=$(ssh -o StrictHostKeyChecking=no vagrant@$SERVER_IP "sudo cat /var/lib/rancher/k3s/server/node-token")

      # Install K3s agent
      curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$TOKEN sh -

      # Install kubectl
      sudo apt-get install -y kubectl
    SHELL
  end
end
