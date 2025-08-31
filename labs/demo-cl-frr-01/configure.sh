#!/usr/bin/env bash
set -e

# =============================================================================
# FRR BGP Demo Lab - Configure Script
# =============================================================================
# This script configures BGP on FRR routers
# Variables are inherited from the main Makefile

echo ">> Configuring BGP on FRR routers..."

# Get pod names
FRR1_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers | grep "${FRR1_NAME:-frr1}" | head -1 | awk '{print $1}')
FRR2_POD=$(oc get pods -n "${NS_DEMO:-demo-cl-frr-01}" --no-headers | grep "${FRR2_NAME:-frr2}" | head -1 | awk '{print $1}')

if [ -z "$FRR1_POD" ] || [ -z "$FRR2_POD" ]; then
    echo "!! Could not find FRR pods"
    exit 1
fi

echo "   ${FRR1_NAME:-frr1} pod: $FRR1_POD"
echo "   ${FRR2_NAME:-frr2} pod: $FRR2_POD"

# Configure BGP on FRR1
echo "   configuring BGP on ${FRR1_NAME:-frr1}..."
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo 'hostname ${FRR1_NAME:-frr1}' > /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo 'router bgp ${FRR1_AS:-65001}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo ' neighbor ${FRR2_ETH1_IP:-10.0.0.2} remote-as ${FRR2_AS:-65002}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo ' address-family ipv4 unicast' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo '  network ${FRR1_NETWORK:-10.35.1.0/24}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo ' exit-address-family' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" bash -c "echo 'exit' >> /etc/frr/bgpd.conf"

# Configure BGP on FRR2
echo "   configuring BGP on ${FRR2_NAME:-frr2}..."
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo 'hostname ${FRR2_NAME:-frr2}' > /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo 'router bgp ${FRR2_AS:-65002}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo ' neighbor ${FRR1_ETH1_IP:-10.0.0.1} remote-as ${FRR1_AS:-65001}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo ' address-family ipv4 unicast' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo '  network ${FRR2_NETWORK:-10.35.2.0/24}' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo ' exit-address-family' >> /etc/frr/bgpd.conf"
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" bash -c "echo 'exit' >> /etc/frr/bgpd.conf"

# Restart BGP daemons
echo "   restarting BGP daemons..."
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" /usr/lib/frr/watchfrr.sh restart bgpd 2>/dev/null || true
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" /usr/lib/frr/watchfrr.sh restart bgpd 2>/dev/null || true

# Configure route-maps
echo "   configuring route-maps..."
sleep 5
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR1_POD" -- docker exec "${FRR1_NAME:-frr1}" vtysh -c "configure terminal" -c "router bgp ${FRR1_AS:-65001}" -c "neighbor ${FRR2_ETH1_IP:-10.0.0.2} route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} in" -c "neighbor ${FRR2_ETH1_IP:-10.0.0.2} route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} out" -c "route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} permit 10" -c "end" -c "write memory" 2>/dev/null || true
oc exec -n "${NS_DEMO:-demo-cl-frr-01}" -it "$FRR2_POD" -- docker exec "${FRR2_NAME:-frr2}" vtysh -c "configure terminal" -c "router bgp ${FRR2_AS:-65002}" -c "neighbor ${FRR1_ETH1_IP:-10.0.0.1} route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} in" -c "neighbor ${FRR1_ETH1_IP:-10.0.0.1} route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} out" -c "route-map ${ROUTE_MAP_NAME:-ALLOW-ALL} permit 10" -c "end" -c "write memory" 2>/dev/null || true

echo ">> BGP configuration completed!"
