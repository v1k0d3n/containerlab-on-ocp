#!/usr/bin/env bash
set -e

# SONiC Spine-Leaf Lab Deployment Script
# This script deploys a spine-leaf topology using SONiC switches

echo ">> Deploying SONiC Spine-Leaf Lab..."
echo "   Namespace: ${NS_DEMO:-demo-cl-sonic-01}"
echo "   Topology: ${TOPOLOGY_NAME:-sonic-spine-leaf}"

# Create namespace
echo ">> Creating namespace..."
oc create namespace "${NS_DEMO:-demo-cl-sonic-01}" --dry-run=client -o yaml | oc apply -f -

# Create ClusterRoleBinding for privileged access
echo ">> Creating ClusterRoleBinding..."
oc create clusterrolebinding "clabernetes-privileged-binding-${NS_DEMO:-demo-cl-sonic-01}" \
    --clusterrole=system:openshift:scc:privileged \
    --serviceaccount="${NS_DEMO:-demo-cl-sonic-01}:clabernetes-launcher-service-account" \
    --dry-run=client -o yaml | oc apply -f -

# Apply topology
echo ">> Applying topology..."
echo "   Using SONiC image: ${SONIC_FULL_IMAGE:-quay.io/bjozsa-redhat/docker-sonic-vs:202505}"
cat topology.yaml | sed "s/{{NS_DEMO}}/${NS_DEMO:-demo-cl-sonic-01}/g" | sed "s/{{TOPOLOGY_NAME}}/${TOPOLOGY_NAME:-sonic-spine-leaf}/g" | sed "s|{{SONIC_FULL_IMAGE}}|${SONIC_FULL_IMAGE:-quay.io/bjozsa-redhat/docker-sonic-vs:202505}|g" | oc apply -f -

# Wait for pods to be ready
echo ">> Waiting for pods to be ready..."
echo "   This may take a few minutes..."

# Wait for topology to be created
sleep 10

# Wait for all pods to be running
echo ">> Waiting for all pods to be running..."
for i in {1..30}; do
    RUNNING_PODS=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep -c "Running" || true)
    TOTAL_PODS=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | wc -l || true)
    
    if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -ge 6 ]; then
        echo ">> All pods are running! ($RUNNING_PODS/$TOTAL_PODS)"
        break
    fi
    
    echo "   Waiting... ($RUNNING_PODS/$TOTAL_PODS pods running)"
    sleep 10
done

# Final status check
echo ">> Final status check..."
oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}"

echo ">> SONiC Spine-Leaf Lab deployment completed!"
echo "   Next step: Run 'make configure-lab LAB=demo-cl-sonic-01' to configure the switches"
