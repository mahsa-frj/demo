#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o nounset
set -o pipefail
set -o xtrace
set -o errexit

# install_dependencies() - Install required dependencies
function install_dependencies {
    sudo apt-get update
    sudo apt-get install -y -qq wget openjdk-8-jre bridge-utils net-tools bsdmainutils make gcc libcurl4-gnutls-dev
}

# install_vpp() - Install VPP
function install_vpp {
    sudo apt-get update
    sudo apt-get install -y -qq apt-transport-https

    # shellcheck disable=SC1091
    source /etc/os-release || source /usr/lib/os-release
    echo "deb [trusted=yes] https://packagecloud.io/fdio/release/ubuntu $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/99fd.io.list
    curl -L https://packagecloud.io/fdio/release/gpgkey | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y -qq vpp vpp-plugin-core vpp-plugin-dpdk
}

# install_vfw_scripts() -
function install_vfw_scripts {
    version=$(cat /opt/config/demo_artifacts_version.txt)
    local ves_path=VES
    local ves_reporting_path="${ves_path}/evel/evel-library"

    pushd /opt
    wget https://raw.githubusercontent.com/mahsa-frj/demo/master/heat/vFW_CNF_CDS/{v_firewall_init,vfirewall}.sh
    chmod +x ./*.sh

    wget https://github.com/mahsa-frj/demo/raw/master/heat/vFW_CNF_CDS/sample-distribution-1.6.0-hc.tar.gz
    tar -zmxf sample-distribution-1.6.0-hc.tar.gz  
    mkdir -p honeycomb
    mv "sample-distribution-$version" honeycomb

    wget https://github.com/mahsa-frj/demo/raw/master/heat/vFW_CNF_CDS/ves-1.6.0-demo.tar.gz
    tar -zmxf ves-1.6.0-demo.tar.gz
    mv "ves-$version" "$ves_path"

    https://github.com/mahsa-frj/demo/raw/master/heat/vFW_CNF_CDS/ves_vfw_reporting-1.6.0-demo.tar.gz
    tar -zmxf ves_vfw_reporting-1.6.0-demo.tar.gz
    mkdir -p $ves_reporting_path/code
    mv "ves_vfw_reporting-$version" "$ves_reporting_path/code/VESreporting"

    chmod +x $ves_reporting_path/code/VESreporting/go-client.sh
    pushd $ves_reporting_path/bldjobs/
    make clean
    make
    sleep 1
    popd

    # TODO(electrocucaracha) Fix it in upstream
    sed -i 's/start vpp/systemctl start vpp/g' v_firewall_init.sh
    mv vfirewall.sh /etc/init.d
    update-rc.d vfirewall.sh defaults
    systemctl start firewall
    popd
}

mkdir -p /opt/config/
echo "${protected_net_cidr:-192.168.20.0/24}" > /opt/config/protected_net_cidr.txt
echo "${vfw_private_ip_0:-192.168.10.100}" > /opt/config/fw_ipaddr.txt
echo "${vsn_private_ip_0:-192.168.20.250}" > /opt/config/sink_ipaddr.txt
echo "${demo_artifacts_version:-1.6.0}" > /opt/config/demo_artifacts_version.txt
echo "${dcae_collector_ip:-10.0.4.1}" > /opt/config/dcae_collector_ip.txt
echo "${dcae_collector_port:-8081}" > /opt/config/dcae_collector_port.txt

echo 'vm.nr_hugepages = 1024' >> /etc/sysctl.conf
sysctl -p

install_dependencies
install_vpp
install_vfw_scripts
