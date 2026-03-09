#!/usr/bin/env bash
# PREP: Run this well in advance of the meeting

# 1. Ensure Trustee and OSC are up and running
echo "Checking core infrastructure..."
oc wait --for=condition=Available deployment/trustee-deployment -n trustee-operator-system --timeout=60s

# 2. Create the Sealed Secret pointer
# Replace with your actual POINTER if it is not already in the environment
echo "Generating Sealed Secret pointer..."
export POINTER=$(podman run --rm quay.io/confidential-devhub/coco-tools:0.3.0 /tools/secret seal vault --resource-uri kbs:///default/fraud-dataset/dataset_key --provider kbs | grep -v "Warning")

# Apply the secret using dry-run to ensure it updates if already present
oc create secret generic fraud-dataset-sealed --from-literal=dataset_key=$POINTER -n default --dry-run=client -o yaml | oc apply -f -

# 3. Pre-provision pods
echo "Starting confidential pods (this may take 15-20 minutes)..."
oc apply -f manifests/sample-fd.yaml
oc apply -f manifests/sealed-fd.yaml

# 4. Wait for completion to confirm Azure VMs are live
echo "Waiting for Azure VM provisioning..."
oc wait --for=condition=Ready pod/sample-fraud-detection --timeout=1200s
oc wait --for=condition=Ready pod/sealed-fraud-detection --timeout=1200s

echo "PREP COMPLETE. The environment is now 'warm' for the demo."