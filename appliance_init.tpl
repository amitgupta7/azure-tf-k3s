#!/usr/bin/env bash
install_home=/home/$SUDO_USER/pod-installer
lockfile=/home/$SUDO_USER/install-status.lock
touch $lockfile

install_k3s() {
  echo "Installing k3s with OPTIONS: $INSTALL_K3S_EXEC"
  curl -sfL https://get.k3s.io | sh -s - $INSTALL_K3S_EXEC 
}

err_report() {
    echo -n "Error at time: " && date
    echo; echo -n "$2 failed on line $1: "
    sed -n "$1p" $0
    echo 1 > $lockfile
    exit
}
trap 'err_report $LINENO $0' ERR

while getopts r:k:s:t:o:n:i: flag
do
    case "${flag}" in
        n) nodeType=${OPTARG};;
        o) pod_owner=${OPTARG};;
        r) masterIp=${OPTARG};;
        k) xkey=${OPTARG};;
        s) xsecret=${OPTARG};;
        t) xtenant=${OPTARG};;
        i) privatePodIp=${OPTARG};;        
    esac
done
#main function

snap install jq
echo "## Attempting to install the securiti appliance ##"
sysctl -w vm.max_map_count=262144 >/dev/null
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
mkdir -p $install_home 

  INSTALL_K3S_EXEC="--token securiti"

  if [ "${nodeType}" = "master" ]
  then
    echo "## Attempting to install master ##"
    install_k3s
    bash /home/azuser/appliance_setup.sh -o ${pod_owner} -k ${xkey} -s ${xsecret} -t ${xtenant}
  else
    INSTALL_K3S_EXEC="agent $INSTALL_K3S_EXEC --server https://$masterIp:6443"
    echo "## sleeping for 60sec for master to come up ##"
    sleep 60
    install_k3s
  fi

echo 0 > $lockfile
