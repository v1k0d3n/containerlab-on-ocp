#!/usr/bin/env bash
set -e

# =============================================================================
# FRR BGP Demo Lab - Test Script
# =============================================================================
# This script tests BGP connectivity in the FRR lab
# Variables are inherited from the main Makefile

echo ">> Testing BGP connectivity in FRR lab..."
echo "   namespace: ${NS_DEMO:-demo-cl-frr-01}"

# Get pod names
FRR1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers | grep "${FRR1_NAME:-frr1}" | head -1 | awk '{print $1}')
FRR2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers | grep "${FRR2_NAME:-frr2}" | head -1 | awk '{print $1}')

if [ -z "$FRR1_POD" ] || [ -z "$FRR2_POD" ]; then
    echo "!! Could not find FRR pods"
    exit 1
fi

echo "   ${FRR1_NAME:-frr1} pod: $FRR1_POD"
echo "   ${FRR2_NAME:-frr2} pod: $FRR2_POD"

# Check readiness
echo "   checking readiness..."
FRR1_READY=$(oc get pod -n "${NS_DEMO:-demo-cl-frr-01}" "$FRR1_POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
FRR2_READY=$(oc get pod -n "${NS_DEMO:-demo-cl-frr-01}" "$FRR2_POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")

if [ "$FRR1_READY" != "true" ] || [ "$FRR2_READY" != "true" ]; then
    echo "!! Pods not ready"
    exit 1
fi

# Check BGP daemon
if ! oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" pgrep bgpd >/dev/null 2>&1 || ! oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" pgrep bgpd >/dev/null 2>&1; then
    echo "!! BGP daemon not running"
    exit 1
fi

# Check IP addresses
ACTUAL_FRR1_ETH1_IP=$(oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" ip addr show "${ETH1_INTERFACE:-eth1}" 2>/dev/null | grep "inet " | grep -v "inet6" | head -1 | awk '{print $2}' | cut -d'/' -f1 || echo "")
ACTUAL_FRR2_ETH1_IP=$(oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" ip addr show "${ETH1_INTERFACE:-eth1}" 2>/dev/null | grep "inet " | grep -v "inet6" | head -1 | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$ACTUAL_FRR1_ETH1_IP" != "${FRR1_ETH1_IP:-10.0.0.1}" ] || [ "$ACTUAL_FRR2_ETH1_IP" != "${FRR2_ETH1_IP:-10.0.0.2}" ]; then
    echo "!! IP addresses not configured correctly"
    echo "   ${FRR1_NAME:-frr1} ${ETH1_INTERFACE:-eth1}: $ACTUAL_FRR1_ETH1_IP"
    echo "   ${FRR2_NAME:-frr2} ${ETH1_INTERFACE:-eth1}: $ACTUAL_FRR2_ETH1_IP"
    exit 1
fi

echo "   ✅ All checks passed"
echo ""

# Network connectivity test
echo ">> Network connectivity test"
echo "   testing ping from ${FRR1_NAME:-frr1} to ${FRR2_NAME:-frr2} (${FRR2_ETH1_IP:-10.0.0.2})..."
if oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" ping -c 3 "${FRR2_ETH1_IP:-10.0.0.2}" >/dev/null 2>&1; then
    echo "   ✅ Ping successful"
else
    echo "   ❌ Ping failed"
fi

echo "   testing ping from ${FRR2_NAME:-frr2} to ${FRR1_NAME:-frr1} (${FRR1_ETH1_IP:-10.0.0.1})..."
if oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" ping -c 3 "${FRR1_ETH1_IP:-10.0.0.1}" >/dev/null 2>&1; then
    echo "   ✅ Ping successful"
else
    echo "   ❌ Ping failed"
fi

echo ""

# BGP session status
echo ">> BGP session status"
echo "   ${FRR1_NAME:-frr1} BGP neighbors:"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" vtysh -c "show ip bgp summary" 2>/dev/null | grep -E "(Neighbor|${FRR2_ETH1_IP:-10.0.0.2})" || echo "   No BGP neighbors found"

echo "   ${FRR2_NAME:-frr2} BGP neighbors:"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" vtysh -c "show ip bgp summary" 2>/dev/null | grep -E "(Neighbor|${FRR1_ETH1_IP:-10.0.0.1})" || echo "   No BGP neighbors found"

echo ""

# BGP routing table
echo ">> BGP routing table"
echo "   ${FRR1_NAME:-frr1} BGP table:"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" vtysh -c "show ip bgp" 2>/dev/null | grep -E "(Network|10.35)" || echo "   No BGP routes found"

echo "   ${FRR2_NAME:-frr2} BGP table:"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" vtysh -c "show ip bgp" 2>/dev/null | grep -E "(Network|10.35)" || echo "   No BGP routes found"

echo ""

# Route reachability test
echo ">> Route reachability test"
echo "   testing ping from ${FRR1_NAME:-frr1} to ${FRR2_NAME:-frr2} loopback (${FRR2_LO_IP:-10.35.2.1})..."
if oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" ping -c 3 "${FRR2_LO_IP:-10.35.2.1}" >/dev/null 2>&1; then
    echo "   ✅ Ping successful"
else
    echo "   ❌ Ping failed"
fi

echo "   testing ping from ${FRR2_NAME:-frr2} to ${FRR1_NAME:-frr1} loopback (${FRR1_LO_IP:-10.35.1.1})..."
if oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" ping -c 3 "${FRR1_LO_IP:-10.35.1.1}" >/dev/null 2>&1; then
    echo "   ✅ Ping successful"
else
    echo "   ❌ Ping failed"
fi

echo ""
echo ">> BGP test completed!"
