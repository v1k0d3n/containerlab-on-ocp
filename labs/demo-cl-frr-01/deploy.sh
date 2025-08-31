#!/usr/bin/env bash
set -e

# =============================================================================
# FRR BGP Demo Lab - Deploy Script
# =============================================================================
# This script deploys the FRR BGP demo lab
# Variables are inherited from the main Makefile

echo ">> Deploying FRR BGP demo lab..."
echo "   Namespace: ${NS_DEMO:-demo-cl-frr-01}"
echo "   Topology: ${TOPOLOGY_NAME:-frr-bgp-demo}"

# Create namespace
oc create namespace "${NS_DEMO:-demo-cl-frr-01}" --dry-run=client -o yaml | oc apply -f -

# Create ClusterRoleBinding for privileged access
oc create clusterrolebinding "clabernetes-privileged-binding-${NS_DEMO:-demo-cl-frr-01}" \
    --clusterrole=system:openshift:scc:privileged \
    --serviceaccount="${NS_DEMO:-demo-cl-frr-01}:clabernetes-launcher-service-account" \
    --dry-run=client -o yaml | oc apply -f -

# Deploy topology
cat topology.yaml | sed "s/{{NS_DEMO}}/${NS_DEMO:-demo-cl-frr-01}/g" | oc apply -f -

echo ">> Waiting for pods to be ready..."
for i in $(seq 1 ${POD_READINESS_TIMEOUT:-120}); do
    READY_PODS=$(oc -n "${NS_DEMO:-demo-cl-frr-01}" get pods --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
    if [ "$READY_PODS" -ge 2 ]; then 
        break
    fi
    echo "   waiting for pods to be ready... ($READY_PODS/2 ready)"
    sleep 2
done

echo ">> FRR BGP Lab deployment completed!"
echo "   To configure BGP: make configure-lab LAB=demo-cl-frr-01"
echo "   To test connectivity: make test-lab LAB=demo-cl-frr-01"
