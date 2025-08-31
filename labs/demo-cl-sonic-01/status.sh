#!/usr/bin/env bash
set -e

# SONiC Spine-Leaf Lab Status Script
# This script shows the current status of the lab

echo ">> SONiC Spine-Leaf Lab Status"
echo "   Namespace: ${NS_DEMO:-demo-cl-sonic-01}"
echo "   Topology: ${TOPOLOGY_NAME:-sonic-spine-leaf}"
echo ""

# Check if namespace exists
if ! oc get namespace "${NS_DEMO:-demo-cl-sonic-01}" >/dev/null 2>&1; then
    echo "❌ Namespace ${NS_DEMO:-demo-cl-sonic-01} does not exist"
    echo "   Run 'make deploy-lab LAB=demo-cl-sonic-01' to deploy the lab"
    exit 1
fi

# Show pod status
echo ">> Pod Status:"
oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}"

# Show topology resource
echo ""
echo ">> Topology Resource:"
oc get topology -n "${NS_DEMO:-demo-cl-sonic-01}" -o yaml | grep -A 5 -B 5 "name\|status"

# Check if pods are running
RUNNING_PODS=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep -c "Running" || true)
TOTAL_PODS=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | wc -l || true)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -ge 6 ]; then
    echo ""
    echo "✅ All pods are running ($RUNNING_PODS/$TOTAL_PODS)"
    
    # Get pod names for status checks
    SPINE1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "spine1" | head -1 | awk '{print $1}')
    SPINE2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "spine2" | head -1 | awk '{print $1}')
    LEAF1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "leaf1" | head -1 | awk '{print $1}')
    LEAF2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "leaf2" | head -1 | awk '{print $1}')
    
    if [ -n "$SPINE1_POD" ] && [ -n "$SPINE2_POD" ] && [ -n "$LEAF1_POD" ] && [ -n "$LEAF2_POD" ]; then
        echo ""
        echo ">> LAG (PortChannel) Status:"
        
        echo "   Spine1 PortChannels:"
        oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 show interfaces portchannel 2>/dev/null || echo "     LAGs not configured yet"
        
        echo "   Leaf1 PortChannels:"
        oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 show interfaces portchannel 2>/dev/null || echo "     LAGs not configured yet"
        
        echo ""
        echo ">> Interface Status:"
        
        echo "   Spine1 Interfaces:"
        oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip addr show 2>/dev/null | grep -E "(eth[0-9]|lo)" || echo "     Interfaces not configured yet"
        
        echo "   Leaf1 Interfaces:"
        oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip addr show 2>/dev/null | grep -E "(eth[0-9]|lo)" || echo "     Interfaces not configured yet"
    fi
else
    echo ""
    echo "⚠️  Not all pods are running ($RUNNING_PODS/$TOTAL_PODS)"
    echo "   Wait for all pods to be ready before running configuration"
fi

echo ""
echo ">> Lab Information:"
echo "   - 2x Spine switches (SONiC OS)"
echo "   - 2x Leaf switches (SONiC OS)"
echo "   - 2x Linux hosts for testing"
echo "   - LAG-based spine-leaf fabric connectivity"
echo "   - Full mesh spine-leaf topology with bundled cross-connects"
echo ""
echo ">> Next Steps:"
if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -ge 6 ]; then
    echo "   ✅ Run 'make configure-lab LAB=demo-cl-sonic-01' to configure LAGs and networking"
    echo "   ✅ Run 'make test-lab LAB=demo-cl-sonic-01' to test connectivity"
else
    echo "   ⏳ Wait for all pods to be running"
    echo "   🔄 Run 'make deploy-lab LAB=demo-cl-sonic-01' to redeploy if needed"
fi
echo "   🗑️  Run 'make destroy-lab LAB=demo-cl-sonic-01' to clean up"
