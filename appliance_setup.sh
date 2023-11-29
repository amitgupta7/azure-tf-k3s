#! /bin/bash
set -e
while getopts o:k:s:t: flag
do
    case "${flag}" in
        o) pod_owner=${OPTARG};;
        k) xkey=${OPTARG};;
        s) xsecret=${OPTARG};;
        t) xtenant=${OPTARG};;
    esac
done
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
install_home=/home/$SUDO_USER/pod-installer
mkdir -p $install_home
cd $install_home
echo $xsecret $xtenant $xkey 
curl -s -X 'POST' \
      'https://app.securiti.ai/core/v1/admin/appliance' \
      -H 'accept: application/json' \
      -H 'X-API-Secret:  '${xsecret} \
      -H 'X-API-Key:  '${xkey} \
      -H 'X-TIDENT:  '${xtenant} \
      -H 'Content-Type: application/json' \
      -d '{
      "owner": "'${pod_owner}'",
      "co_owners": [],
      "name": "localtest-'$(date +"%s")'",
      "desc": "",
      "send_notification": false
      }' > sai_appliance.txt
  
SAI_LICENSE=$(cat sai_appliance.txt| jq -r '.data.license')
echo "License:"$SAI_LICENSE
curl -s -X 'GET' 'https://app.securiti.ai/core/v1/admin/appliance/download_url' \
    -H 'accept: application/json' \
    -H 'X-API-Secret:  '${xsecret} \
    -H 'X-API-Key:  '${xkey} \
    -H 'X-TIDENT:  '${xtenant} \
    > sai_download.txt
PACKAGE_DIR=securiti-appliance-installer
PACKAGE_NAME=$PACKAGE_DIR.tar.gz
DOWNLOAD_URL=$(cat sai_download.txt| jq -r '.download_url')
echo "download url:"$DOWNLOAD_URL
curl "$DOWNLOAD_URL" --output $PACKAGE_NAME
tar -xvzf $PACKAGE_NAME
cd $PACKAGE_DIR
cat > values.yaml << EOF
global:
    registry: "app.securiti.ai"
    appliance_install_type: online
EOF
cat > registrykey.json << EOF
{"auths":{"app.securiti.ai":{"auth":"$SAI_LICENSE"}}}
EOF
cat registrykey.json
kubectl create secret generic registrykey --from-file=.dockerconfigjson=registrykey.json --type=kubernetes.io/dockerconfigjson
./helm upgrade --install priv-appliance securiti-appliance-0.1.0.tgz -f values.yaml
kubectl get pods -A
