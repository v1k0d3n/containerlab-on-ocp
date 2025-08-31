#!/usr/bin/env bash
set -e

# SONiC Spine-Leaf Lab Destroy Script
# This script cleans up the lab resources

echo ">> Destroying SONiC Spine-Leaf Lab..."
echo "   Namespace: ${NS_DEMO:-demo-cl-sonic-01}"
echo "   Topology: ${TOPOLOGY_NAME:-sonic-spine-leaf}"

# Check if namespace exists
if ! oc get namespace "${NS_DEMO:-demo-cl-sonic-01}" >/dev/null 2>&1; then
    echo "❌ Namespace ${NS_DEMO:-demo-cl-sonic-01} does not exist"
    echo "   Lab is already destroyed or was never deployed"
    exit 0
fi

# Delete topology
echo ">> Deleting topology..."
oc delete topology "${TOPOLOGY_NAME:-sonic-spine-leaf}" -n "${NS_DEMO:-demo-cl-sonic-01}" --ignore-not-found=true

# Wait for topology deletion
echo ">> Waiting for topology deletion..."
sleep 10

# Delete ClusterRoleBinding
echo ">> Deleting ClusterRoleBinding..."
oc delete clusterrolebinding "clabernetes-privileged-binding-${NS_DEMO:-demo-cl-sonic-01}" --ignore-not-found=true

# Delete namespace
echo ">> Deleting namespace..."
oc delete namespace "${NS_DEMO:-demo-cl-sonic-01}" --ignore-not-found=true

# Wait for namespace deletion
echo ">> Waiting for namespace deletion..."
sleep 10

# Final check
if oc get namespace "${NS_DEMO:-demo-cl-sonic-01}" >/dev/null 2>&1; then
    echo "⚠️  Namespace still exists, forcing deletion..."
    oc delete namespace "${NS_DEMO:-demo-cl-sonic-01}" --force --grace-period=0
fi

echo ">> SONiC Spine-Leaf Lab destruction completed!"
echo "   All resources have been cleaned up"
