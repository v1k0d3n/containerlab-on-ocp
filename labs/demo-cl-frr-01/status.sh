#!/usr/bin/env bash
set -e

# =============================================================================
# FRR BGP Demo Lab - Status Script
# =============================================================================
# This script shows the status of the FRR lab
# Variables are inherited from the main Makefile

echo ">> FRR BGP Lab Status:"
echo "   Namespace: ${NS_DEMO:-demo-cl-frr-01}"
echo "   Topology: ${TOPOLOGY_NAME:-frr-bgp-demo}"

# Show pods
oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" -o wide 2>/dev/null || echo "   No pods found"

# Show topology resource
echo "   Topology resource:"
oc get topology -n "${NS_DEMO:-demo-cl-frr-01}" "${TOPOLOGY_NAME:-frr-bgp-demo}" -o yaml 2>/dev/null | grep -E "(name:|namespace:|status:)" || echo "   No topology found"

# Show BGP status if pods are running
FRR1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers 2>/dev/null | grep "${FRR1_NAME:-frr1}" | head -1 | awk '{print $1}' || echo "")
FRR2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers 2>/dev/null | grep "${FRR2_NAME:-frr2}" | head -1 | awk '{print $1}' || echo "")

if [ -n "$FRR1_POD" ] && [ -n "$FRR2_POD" ]; then
    echo ""
    echo "   BGP Status:"
    echo "   ${FRR1_NAME:-frr1} BGP neighbors:"
    oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" vtysh -c "show ip bgp summary" 2>/dev/null | grep -E "(Neighbor|${FRR2_ETH1_IP:-10.0.0.2})" || echo "   No BGP neighbors found"
    
    echo "   ${FRR2_NAME:-frr2} BGP neighbors:"
    oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" vtysh -c "show ip bgp summary" 2>/dev/null | grep -E "(Neighbor|${FRR1_ETH1_IP:-10.0.0.1})" || echo "   No BGP neighbors found"
fi
