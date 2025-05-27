#!/usr/bin/env sh

sudo apt update
sudo apt -y install --no-install-recommends --no-install-suggests \
    gpg wget lsb-release unzip
mkdir ~/terraform && cd ~/terraform
wget https://hashicorp-releases.yandexcloud.net/terraform/1.12.1/terraform_1.12.1_linux_386.zip
sudo apt install unzip
unzip terraform_1.12.1_linux_386.zip
export PATH=$PATH:~/terraform
terraform -install-autocomplete
cat > ~/.terraformrc <<EOF
provider_installation {
    network_mirror {
        url = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
}
    direct {
        exclude = ["registry.terraform.io/*/*"]
    }
}
EOF
echo 'export PATH=$PATH:~/terraform' >> ~/.bashrc
echo 'export PATH=$PATH:~/terraform' >> ~/.profile
#terraform init
