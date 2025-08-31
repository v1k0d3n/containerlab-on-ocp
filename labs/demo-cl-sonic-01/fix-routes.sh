#!/usr/bin/env bash
set -e

echo ">> Fixing missing static routes for cross-leaf connectivity..."

# Get pod names
SPINE1_POD=$(oc get pods -n "demo-cl-sonic-01" --no-headers | grep "spine1" | head -1 | awk '{print $1}')
SPINE2_POD=$(oc get pods -n "demo-cl-sonic-01" --no-headers | grep "spine2" | head -1 | awk '{print $1}')
LEAF1_POD=$(oc get pods -n "demo-cl-sonic-01" --no-headers | grep "leaf1" | head -1 | awk '{print $1}')
LEAF2_POD=$(oc get pods -n "demo-cl-sonic-01" --no-headers | grep "leaf2" | head -1 | awk '{print $1}')

echo "   Found pods:"
echo "     Spine1: $SPINE1_POD"
echo "     Spine2: $SPINE2_POD"
echo "     Leaf1: $LEAF1_POD"
echo "     Leaf2: $LEAF2_POD"

# Function to add route safely
add_route() {
    local pod=$1
    local switch=$2
    local network=$3
    local gateway=$4
    local interface=$5
    
    echo "   Adding route $network via $gateway on $interface to $switch..."
    oc exec -n "demo-cl-sonic-01" "$pod" -- docker exec "$switch" ip route add "$network" via "$gateway" dev "$interface" 2>/dev/null || echo "     Note: Route may already exist"
}

echo ">> Adding missing static routes..."

echo "   Adding routes to Spine1 for cross-connectivity..."
add_route "$SPINE1_POD" "spine1" "10.1.3.0/30" "10.1.1.2" "eth1"  # Spine1 -> Leaf1 -> Spine2
add_route "$SPINE1_POD" "spine1" "10.1.4.0/30" "10.1.2.2" "eth2"  # Spine1 -> Leaf2 -> Spine2
add_route "$SPINE1_POD" "spine1" "10.2.1.0/24" "10.1.1.2" "eth1"  # Spine1 -> Leaf1 -> Host1
add_route "$SPINE1_POD" "spine1" "10.2.2.0/24" "10.1.2.2" "eth2"  # Spine1 -> Leaf2 -> Host2

echo "   Adding routes to Spine2 for cross-connectivity..."
add_route "$SPINE2_POD" "spine2" "10.1.1.0/30" "10.1.3.2" "eth1"  # Spine2 -> Leaf1 -> Spine1
add_route "$SPINE2_POD" "spine2" "10.1.2.0/30" "10.1.4.2" "eth2"  # Spine2 -> Leaf2 -> Spine1
add_route "$SPINE2_POD" "spine2" "10.2.1.0/24" "10.1.3.2" "eth1"  # Spine2 -> Leaf1 -> Host1
add_route "$SPINE2_POD" "spine2" "10.2.2.0/24" "10.1.4.2" "eth2"  # Spine2 -> Leaf2 -> Host2

echo "   Adding routes to Leaf1 for cross-connectivity..."
add_route "$LEAF1_POD" "leaf1" "10.1.2.0/30" "10.1.1.1" "eth1"  # Leaf1 -> Spine1 -> Leaf2
add_route "$LEAF1_POD" "leaf1" "10.1.4.0/30" "10.1.3.1" "eth2"  # Leaf1 -> Spine2 -> Leaf2
add_route "$LEAF1_POD" "leaf1" "10.2.2.0/24" "10.1.1.1" "eth1"  # Leaf1 -> Spine1 -> Leaf2 -> Host2

echo "   Adding routes to Leaf2 for cross-connectivity..."
add_route "$LEAF2_POD" "leaf2" "10.1.1.0/30" "10.1.2.1" "eth1"  # Leaf2 -> Spine1 -> Leaf1
add_route "$LEAF2_POD" "leaf2" "10.1.3.0/30" "10.1.4.1" "eth2"  # Leaf2 -> Spine2 -> Leaf1
add_route "$LEAF2_POD" "leaf2" "10.2.1.0/24" "10.1.2.1" "eth1"  # Leaf2 -> Spine1 -> Leaf1 -> Host1

echo ">> Enabling IP forwarding on all switches..."
oc exec -n "demo-cl-sonic-01" "$SPINE1_POD" -- docker exec spine1 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
oc exec -n "demo-cl-sonic-01" "$SPINE2_POD" -- docker exec spine2 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
oc exec -n "demo-cl-sonic-01" "$LEAF1_POD" -- docker exec leaf1 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
oc exec -n "demo-cl-sonic-01" "$LEAF2_POD" -- docker exec leaf2 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

echo "   ✅ Static routes and IP forwarding configured!"
echo "   Next step: Run 'make test-lab LAB=demo-cl-sonic-01' to test connectivity"
