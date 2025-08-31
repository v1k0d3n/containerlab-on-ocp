#!/usr/bin/env bash
set -e

# =============================================================================
# FRR BGP Demo Lab - Destroy Script
# =============================================================================
# This script cleans up the FRR lab
# Variables are inherited from the main Makefile

echo ">> Cleaning up FRR BGP demo lab..."

# Delete topology
oc delete topology -n "${NS_DEMO:-demo-cl-frr-01}" "${TOPOLOGY_NAME:-frr-bgp-demo}" --ignore-not-found || true

# Delete ClusterRoleBinding
oc delete clusterrolebinding "clabernetes-privileged-binding-${NS_DEMO:-demo-cl-frr-01}" --ignore-not-found || true

# Delete namespace
oc delete ns "${NS_DEMO:-demo-cl-frr-01}" || true

echo ">> FRR BGP Lab cleanup completed!"
