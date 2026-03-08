#!/usr/bin/env bash

# Färger
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[38;2;102;204;255m'
NC='\033[0m'

echo -e "${BLUE}=== Initierar variabler för confi_demo ===${NC}"

# 1. Azure & Cluster info
CLOUD_CONF=$(oc get configmap cloud-conf -n openshift-cloud-controller-manager -o jsonpath='{.data.cloud\.conf}')
export SUBSCRIPTION_ID=$(echo "$CLOUD_CONF" | jq -r '.subscriptionId')
export CLUSTER_RESOURCE_GROUP=$(echo "$CLOUD_CONF" | jq -r '.resourceGroup')
export USER_RESOURCE_GROUP=$(echo "$CLOUD_CONF" | jq -r '.vnetResourceGroup')
export AZURE_REGION=$(echo "$CLOUD_CONF" | jq -r '.location')
export VNET_NAME=$(echo "$CLOUD_CONF" | jq -r '.vnetName')
export SUBNET_NAME=$(echo "$CLOUD_CONF" | jq -r '.subnetName')

export AZURE_SUBNET_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${USER_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${VNET_NAME}/subnets/${SUBNET_NAME}"

# 2. Trustee info
export DOMAIN=$(oc get ingress.config/cluster -o jsonpath='{.spec.domain}')
export TRUSTEE_HOST="https://$(oc get route -n trustee-operator-system kbs-service -o jsonpath='{.spec.host}')"
export TRUSTEE_CERT=$(oc get secret trustee-tls-cert -n trustee-operator-system -o json | jq -r '.data."tls.crt"' | base64 --decode)

# 3. PCR8 Beräkning (Hämtar från ../trustee/initdata.toml) 
INITDATA_FILE="../trustee/initdata.toml"
if [ -f "$INITDATA_FILE" ]; then
    hash=$(sha256sum "$INITDATA_FILE" | cut -d' ' -f1)
    initial_pcr="0000000000000000000000000000000000000000000000000000000000000000"
    export PCR8_HASH=$(echo -n "$initial_pcr$hash" | xxd -r -p | sha256sum | cut -d' ' -f1)
    echo -e "[${GREEN}OK${NC}] PCR8_HASH beräknad från $INITDATA_FILE"
else
    echo -e "[${RED}FAIL${NC}] Hittade inte $INITDATA_FILE"
fi

# 4. Sealed Secret POINTER (Modul 12) 
export POINTER=$(podman run --rm quay.io/confidential-devhub/coco-tools:0.3.0 /tools/secret seal vault --resource-uri kbs:///default/fraud-dataset/dataset_key --provider kbs | grep -v "Warning")

echo -e "${GREEN}Klart! Kör nu: source ./vars.sh${NC}"