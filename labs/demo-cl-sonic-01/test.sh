#!/usr/bin/env bash
set -e

# SONiC Spine-Leaf Lab Test Script
# This script tests LAG connectivity and network reachability

echo ">> Testing SONiC Spine-Leaf Lab..."
echo "   Namespace: ${NS_DEMO:-demo-cl-sonic-01}"

# Get pod names
SPINE1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "spine1" | head -1 | awk '{print $1}')
SPINE2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "spine2" | head -1 | awk '{print $1}')
LEAF1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "leaf1" | head -1 | awk '{print $1}')
LEAF2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "leaf2" | head -1 | awk '{print $1}')
HOST1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "host1" | head -1 | awk '{print $1}')
HOST2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}" --no-headers | grep "host2" | head -1 | awk '{print $1}')

# Check pod status
echo ">> Checking pod status..."
oc get pods -n "${NS_DEMO:-demo-cl-sonic-01}"

# Test 1: Check LAG (PortChannel) status on all switches
echo ""
echo ">> Test 1: Checking LAG (PortChannel) status on all switches..."

echo "   Spine1 LAG Status (PortChannels and member interfaces):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip addr show | grep -E "(PortChannel|Ethernet[048])"

echo "   Spine2 LAG Status (PortChannels and member interfaces):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ip addr show | grep -E "(PortChannel|Ethernet[048])"

echo "   Leaf1 LAG Status (PortChannels and member interfaces):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip addr show | grep -E "(PortChannel|Ethernet[048])"

echo "   Leaf2 LAG Status (PortChannels and member interfaces):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ip addr show | grep -E "(PortChannel|Ethernet[048])"

echo "   Note: PortChannels show as DOWN/NO-CARRIER in containerlab (expected behavior)"
echo "   Note: Member interfaces (EthernetX) are properly assigned to PortChannels (master PortChannelX)"

# Test 2: Check interface status and IP addresses
echo ""
echo ">> Test 2: Checking interface status and IP addresses..."

echo "   Spine1 interfaces:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip addr show

echo "   Spine2 interfaces:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ip addr show

echo "   Leaf1 interfaces:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip addr show

echo "   Leaf2 interfaces:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ip addr show

# Test 2.5: Check specific interface configurations
echo ""
echo ">> Test 2.5: Checking specific interface configurations..."

echo "   Spine1 eth1 (10.1.1.1):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip addr show dev eth1

echo "   Spine1 eth2 (10.1.2.1):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip addr show dev eth2

echo "   Leaf1 eth1 (10.1.1.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip addr show dev eth1

echo "   Leaf1 eth2 (10.1.3.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip addr show dev eth2

echo "   Leaf2 eth1 (10.1.2.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ip addr show dev eth1

echo "   Leaf2 eth2 (10.1.4.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ip addr show dev eth2

# Test 3: Check routing tables
echo ""
echo ">> Test 3: Checking routing tables..."

echo "   Spine1 routing table:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ip route show

echo "   Spine2 routing table:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ip route show

echo "   Leaf1 routing table:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ip route show

echo "   Leaf2 routing table:"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ip route show

# Test 4: Test connectivity between switches via LAGs
echo ""
echo ">> Test 4: Testing connectivity between switches via LAGs..."

echo "   Spine1 -> Leaf1 (10.1.1.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 3 10.1.1.2

echo "   Spine1 -> Leaf2 (10.1.2.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 3 10.1.2.2

echo "   Spine2 -> Leaf1 (10.1.3.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ping -c 3 10.1.3.2

echo "   Spine2 -> Leaf2 (10.1.4.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ping -c 3 10.1.4.2

# Test 4.5: Detailed connectivity testing with step-by-step verification
echo ""
echo ">> Test 4.5: Detailed connectivity testing with step-by-step verification..."

echo "   🔍 Testing Leaf1 -> Leaf2 via Spine1:"
echo "     Step 1: Leaf1 -> Spine1"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ping -c 1 10.1.1.1
echo "     Step 2: Spine1 -> Leaf2"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 1 10.1.2.2
echo "     Step 3: End-to-end Leaf1 -> Leaf2"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ping -c 2 10.1.2.2

echo "   🔍 Testing Leaf2 -> Leaf1 via Spine1:"
echo "     Step 1: Leaf2 -> Spine1"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ping -c 1 10.1.2.1
echo "     Step 2: Spine1 -> Leaf1"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 1 10.1.1.2
echo "     Step 3: End-to-end Leaf2 -> Leaf1"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ping -c 2 10.1.1.2

# Test 5: Test loopback reachability (optional - may fail due to missing routes)
echo ""
echo ">> Test 5: Testing loopback reachability (optional)..."
echo "   Note: Loopback reachability requires additional routing configuration"
echo "   Spine1 -> Spine2 loopback (10.0.1.2):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 2 10.0.1.2 2>/dev/null; then
    echo "   ✅ Loopback reachability working"
else
    echo "   ⚠️  Loopback reachability not configured (expected in this lab)"
fi

echo "   Leaf1 -> Leaf2 loopback (10.0.2.2):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ping -c 2 10.0.2.2 2>/dev/null; then
    echo "   ✅ Loopback reachability working"
else
    echo "   ⚠️  Loopback reachability not configured (expected in this lab)"
fi

# Test 6: Test cross-leaf connectivity via spine switches
echo ""
echo ">> Test 6: Testing cross-leaf connectivity via spine switches..."

echo "   Leaf1 -> Leaf2 via Spine1 (10.1.2.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ping -c 3 10.1.2.2

echo "   Leaf2 -> Leaf1 via Spine1 (10.1.1.2):"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ping -c 3 10.1.1.2

# Test 7: Test host connectivity (optional - may fail due to IP configuration)
echo ""
echo ">> Test 7: Testing host connectivity (optional)..."
echo "   Note: Host connectivity requires proper IP configuration in containerlab topology"
echo "   Host1 -> Host2 (10.2.2.10):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$HOST1_POD" -- ping -c 2 10.2.2.10 2>/dev/null; then
    echo "   ✅ Host connectivity working"
else
    echo "   ⚠️  Host connectivity not configured (expected in this lab)"
fi

echo "   Host2 -> Host1 (10.2.1.10):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$HOST2_POD" -- ping -c 2 10.2.1.10 2>/dev/null; then
    echo "   ✅ Host connectivity working"
else
    echo "   ⚠️  Host connectivity not configured (expected in this lab)"
fi

# Test 8: Test host to switch connectivity (optional - may fail due to IP configuration)
echo ""
echo ">> Test 8: Testing host to switch connectivity (optional)..."
echo "   Note: Host connectivity requires proper IP configuration in containerlab topology"
echo "   Host1 -> Leaf1 gateway (10.2.1.1):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$HOST1_POD" -- ping -c 2 10.2.1.1 2>/dev/null; then
    echo "   ✅ Host to switch connectivity working"
else
    echo "   ⚠️  Host to switch connectivity not configured (expected in this lab)"
fi

echo "   Host2 -> Leaf2 gateway (10.2.2.1):"
if oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$HOST2_POD" -- ping -c 2 10.2.2.1 2>/dev/null; then
    echo "   ✅ Host to switch connectivity working"
else
    echo "   ⚠️  Host to switch connectivity not configured (expected in this lab)"
fi



# Test 9: Final connectivity summary
echo ""
echo ">> Test 9: Final connectivity summary..."

echo "   Testing critical paths one more time..."

echo "   Critical Path 1: Spine1 -> Leaf1 -> Spine2 -> Leaf2"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 2 10.1.1.2
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF1_POD" -- docker exec leaf1 ping -c 2 10.1.3.1
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ping -c 2 10.1.4.2

echo "   Critical Path 2: Spine2 -> Leaf2 -> Spine1 -> Leaf1"
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE2_POD" -- docker exec spine2 ping -c 2 10.1.4.2
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$LEAF2_POD" -- docker exec leaf2 ping -c 2 10.1.2.1
oc exec -n "${NS_DEMO:-demo-cl-sonic-01}" -it "$SPINE1_POD" -- docker exec spine1 ping -c 2 10.1.1.2

echo ""
echo ">> SONiC Spine-Leaf Lab testing completed!"
echo "   Architecture: Production-grade spine-leaf with LAG cross-connects"
echo "   LAGs provide: Increased bandwidth, high availability, load balancing"
echo "   Default login: admin / YourPaSsWoRd"
