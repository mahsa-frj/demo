#!/bin/bash

REPO_URL_BLOB=$(cat /opt/config/repo_url_blob.txt)
REPO_URL_ARTIFACTS=$(cat /opt/config/repo_url_artifacts.txt)
DEMO_ARTIFACTS_VERSION=$(cat /opt/config/demo_artifacts_version.txt)
INSTALL_SCRIPT_VERSION=$(cat /opt/config/install_script_version.txt)
CLOUD_ENV=$(cat /opt/config/cloud_env.txt)

# Download required dependencies
add-apt-repository -y ppa:openjdk-r/ppa
apt-get update
apt-get install -y make gcc wget openjdk-8-jdk bridge-utils libcurl4-openssl-dev apt-transport-https ca-certificates
sleep 1

# Download vLB demo code for load balancer
mkdir /opt/config
mkdir /opt/FDserver
cd /opt

wget $REPO_URL_BLOB/org.openecomp.demo/vnfs/vlb/$INSTALL_SCRIPT_VERSION/v_lb_init.sh
wget $REPO_URL_BLOB/org.openecomp.demo/vnfs/vlb/$INSTALL_SCRIPT_VERSION/vlb.sh
wget $REPO_URL_BLOB/org.openecomp.demo/vnfs/vlb/$INSTALL_SCRIPT_VERSION/dnsmembership.sh
wget $REPO_URL_BLOB/org.openecomp.demo/vnfs/vlb/$INSTALL_SCRIPT_VERSION/add_dns.sh
wget $REPO_URL_BLOB/org.openecomp.demo/vnfs/vlb/$INSTALL_SCRIPT_VERSION/remove_dns.sh
wget $REPO_URL_ARTIFACTS/org/openecomp/demo/vnf/vlb/dns-manager/$DEMO_ARTIFACTS_VERSION/dns-manager-$DEMO_ARTIFACTS_VERSION.jar
wget $REPO_URL_ARTIFACTS/org/openecomp/demo/vnf/ves/ves/$DEMO_ARTIFACTS_VERSION/ves-$DEMO_ARTIFACTS_VERSION-demo.tar.gz
wget $REPO_URL_ARTIFACTS/org/openecomp/demo/vnf/ves/ves_vlb_reporting/$DEMO_ARTIFACTS_VERSION/ves_vlb_reporting-$DEMO_ARTIFACTS_VERSION-demo.tar.gz

tar -zxvf ves-$DEMO_ARTIFACTS_VERSION-demo.tar.gz
mv ves-$DEMO_ARTIFACTS_VERSION VES
tar -zxvf ves_vlb_reporting-$DEMO_ARTIFACTS_VERSION-demo.tar.gz
mv ves_vlb_reporting-$DEMO_ARTIFACTS_VERSION VESreporting_vLB

mv VESreporting_vLB /opt/VES/code/evel_training/VESreporting
mv dns-manager-$DEMO_ARTIFACTS_VERSION.jar /opt/FDserver/dns-manager-$DEMO_ARTIFACTS_VERSION.jar
mv dnsmembership.sh /opt/FDserver/dnsmembership.sh
mv add_dns.sh /opt/FDserver/add_dns.sh
mv remove_dns.sh /opt/FDserver/remove_dns.sh
rm *.tar.gz

chmod +x v_lb_init.sh
chmod +x vlb.sh
chmod +x /opt/VES/code/evel_training/VESreporting/go-client.sh
chmod +x /opt/FDserver/dnsmembership.sh
chmod +x /opt/FDserver/add_dns.sh
chmod +x /opt/FDserver/remove_dns.sh

# Install VPP
export UBUNTU="trusty"
export RELEASE=".stable.1609"
rm /etc/apt/sources.list.d/99fd.io.list
echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
apt-get update
apt-get install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
sleep 1

# Install VES
cd /opt/VES/bldjobs/
make clean
make
sleep 1

# Run instantiation script
cd /opt
mv vlb.sh /etc/init.d
update-rc.d vlb.sh defaults
./v_lb_init.sh