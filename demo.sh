#!/usr/bin/env bash
. ./utils/demo-magic.sh
DEMO_PROMPT="${GREEN}➜${CYAN}[aro-coco]$ ${COLOR_RESET}"
TYPE_SPEED=30
USE_CLICKER=true

# Colors
BLUE='\033[38;2;102;204;255m'; GREEN='\033[38;5;41m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'

# Hide warnings to keep the output clean
oc() { command oc "$@" 2>&1 | sed '/^Warning:/d'; return ${PIPESTATUS[0]}; }
export -f oc

clear

# --- INTRO: Architecture ---

cowsay  "Confidential Containers (CoCo) on ARO."
echo ""
wait
echo -e "${BLUE}========== Architecture & Personas: Responsibility Model ==========${RESET}"
wait
echo -e " 
   OpSec (Trusted Zone)        vs       Cluster Admin (Untrusted Zone) 

   [ PERSONA: OpSec ] <----------+  [ PERSONA: Cluster Admin ]
   (Manages Trustee)             |    (Manages ARO Cluster)
          |                      |           |
          v                      |           v
   +--------------+              |    +--------------------------+
   |   TRUSTEE    |              |    |    ARO WORKER NODE       |
   | (Attestation)|              |    | (Runs OSC Operator)      | 
   +--------------+              |    +--------------------------+
          ^                      |           |
          |                      |           v
          |                      |    +--------------------------+
          |      ATTESTATION     |    |    CONFIDENTIAL VM       |
          +----------------------+    |    (Peer Pod / TEE)      |
          |      & KEYS          |    |                          |
          |                      |    |  +--------------------+  |
          |                      |    |  |  [ APP DEVELOPER ] |  |
          +---------------------------+  |  (Application Code) |  |
                                      |  +--------------------+  |
                                      +--------------------------+
"
echo -e "${YELLOW}Note:${RESET} The Cluster Admin can see the pod but cannot access data inside the enclave."
wait

# --- BASELINE ---
clear
echo -e "${BLUE}1. CURRENT STATE: INFRASTRUCTURE${RESET}"
echo ""
wait
pei "oc get nodes"
wait
echo ""
echo -e "\nAzure Instances in operation (note the DC4as_v5 sizes):"
# Showing the customer that pods are running in specialized Azure VMs
echo ""
wait
pei "az vm list --query \"[].{Name:name, Size:hardwareProfile.vmSize, State:provisioningState}\" --output table"
wait
echo ""

# --- SIMPLICITY ---
clear
echo -e "${BLUE}2. DEVELOPER SIMPLICITY${RESET}"
echo ""
echo "The developer only needs to change one line: runtimeClassName."
echo ""
wait
pei "cat manifests/sample-fd.yaml"
echo -e "\nThe pod is already running in a TEE (Trusted Execution Environment)."
echo ""
wait
pei "oc get pod sample-fraud-detection"
wait

# --- AUTOMATION & POLICY ---
clear
echo -e "${BLUE}3. AUTOMATION & POLICY${RESET}"
echo ""
echo "The Trustee server automatically rejects unsigned images."
echo ""
wait
pei "oc extract secret/trustee-image-policy -n trustee-operator-system --to=-"
wait
echo -e "\n${YELLOW}Security Note:${RESET} Any image not matching this signature policy will be blocked at the hardware level."
wait

# --- PERSISTENT DATA & SEALED SECRETS ---
clear
echo -e "${BLUE}4. PERSISTENT DATA & KEY MANAGEMENT${RESET}"
echo "We use 'Sealed Secrets' - a secure link to the Trustee server."
echo "The administrator only sees a 'Resource Pointer', not the actual key:"
echo ""
wait
pei "oc get secret fraud-dataset-sealed -o jsonpath='{.data.dataset_key}' | base64 -d"
wait
echo -e "\n\n${GREEN}Final Proof: Application has decrypted data inside the VM enclave${RESET}"
# Displaying live logs to show the successful decryption
pei "oc logs pods/sealed-fraud-detection | head -n 10"
echo ""
echo -e "\n${GREEN}Success: The app has started and decrypted its dataset!${RESET}"
wait
echo ""

# --- LOGS VS EXEC ---
clear
echo -e "${BLUE}5. LOGS VS EXEC: Transparency without Intrusion${RESET}"
echo "As you saw, we can still monitor application health via logs (stdout)..."
wait
echo -e "\n...but we CANNOT break in to run unauthorized commands:"
# This will fail as per the security policy
wait
pei "oc exec pods/sealed-fraud-detection -- whoami"
echo "" 
echo -e "\n${RED}Result:${RESET} Command denied."
echo "This is because 'enable_vmm_mgmt_exec' is set to 'false' in our security policy."
echo "No cluster administrator can peek into the encrypted runtime."
wait

# --- CONCLUSION ---
clear
cowsay "Summary"
echo ""
echo "* Isolated VM instances protect data from infrastructure admins."
echo "* Automatic policy enforcement (Trustee Attestation)."
echo "* Secure access to persistent data via Sealed Secrets."
echo ""
echo -e "${BLUE}========== Responsibility Model Review ==========${RESET}"
echo -e " 
   OpSec (Trusted)           vs       Cluster Admin (Untrusted) 

   [ PERSONA: OpSec ] <----------+  [ PERSONA: Cluster Admin ]
   (Trustee & Policies)          |    (Infrastructure)
          |                      |           |
          v                      |           v
   +--------------+              |    +--------------------------+
   |   TRUSTEE    |              |    |    ARO WORKER NODE       |
   | (Attestation)|              |    | (Management Layer)       | 
   +--------------+              |    +--------------------------+
          ^                      |           |
          |                      |           v
          |                      |    +--------------------------+
          |      ATTESTATION     |    |    CONFIDENTIAL VM       |
          +----------------------+    |    (Hardware Encrypted)  |
          |      & KEYS          |    |                          |
          |                      |    |  +--------------------+  |
          |                      |    |  |  [ APP DEVELOPER ] |  |
          +---------------------------+  |  (Business Logic)  |  |
                                      |  +--------------------+  |
                                      +--------------------------+
"
wait