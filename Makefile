# =============================================================================
# Clabernetes on OpenShift - Main Makefile
# =============================================================================
# This Makefile provides a modular approach to deploying Clabernetes and labs
# 
# Usage:
#   make deploy-containerlab                 # Deploy only Clabernetes
#   make deploy-lab LAB=my-lab               # Deploy only the lab
#   make deploy-all LAB=my-lab               # Deploy Clabernetes + lab
#   make configure-lab LAB=my-lab            # Configure the lab
#   make test-lab LAB=my-lab                 # Test the lab
#   make status-lab LAB=my-lab               # Show lab status
#   make destroy-lab LAB=my-lab              # Clean up lab
#   make destroy-containerlab                # Clean up Clabernetes
#   make destroy-all LAB=my-lab              # Clean up everything

# =============================================================================
# CLABERNETES DEPLOYMENT VARIABLES
# =============================================================================
# These variables control the Clabernetes deployment
# Modify these to match your OpenShift environment

# OpenShift Cluster Configuration
OCP_DOMAIN ?= hub.lab.ocp.run

# Clabernetes Deployment Configuration
NS_MGR ?= c9s
RELEASE ?= clabernetes
CHART ?= oci://ghcr.io/srl-labs/clabernetes/clabernetes
VERSION ?= 0.3.1
HOST_UI ?= ui-$(NS_MGR).apps.$(OCP_DOMAIN)

# Deployment Timeouts
DEPLOYMENT_TIMEOUT ?= 5
POD_READINESS_TIMEOUT ?= 120

# =============================================================================
# LAB CONFIGURATION VARIABLES
# =============================================================================
# These variables are used by labs. Each lab can override these as needed.
# The sample lab (demo-cl-frr-01) uses these default values.

# Sample Lab Configuration (demo-cl-frr-01)
NS_DEMO ?= demo-cl-frr-01
TOPOLOGY_NAME ?= frr-bgp-demo

# FRR BGP Demo Lab Configuration
FRR_IMAGE ?= frrouting/frr:latest
FRR1_NAME ?= frr1
FRR2_NAME ?= frr2
FRR1_AS ?= 65001
FRR2_AS ?= 65002
FRR1_ETH1_IP ?= 10.0.0.1
FRR2_ETH1_IP ?= 10.0.0.2
FRR1_LO_IP ?= 10.35.1.1
FRR2_LO_IP ?= 10.35.2.1
FRR1_NETWORK ?= 10.35.1.0/24
FRR2_NETWORK ?= 10.35.2.0/24
FRR1_MGMT_IP ?= 192.168.1.1
FRR2_MGMT_IP ?= 192.168.2.1

# Network Configuration
ETH1_INTERFACE ?= eth1
LO_INTERFACE ?= lo
ETH1_SUBNET ?= 24
LO_SUBNET ?= 24
CNI_NETWORK ?= vlan3
CNI_NAMESPACE ?= default

# BGP Configuration
ROUTE_MAP_NAME ?= ALLOW-ALL

# SONiC Lab Configuration (demo-cl-sonic-01)
SONIC_NS_DEMO ?= demo-cl-sonic-01
SONIC_TOPOLOGY_NAME ?= sonic-spine-leaf
SONIC_SPINE1_NAME ?= spine1
SONIC_SPINE2_NAME ?= spine2
SONIC_LEAF1_NAME ?= leaf1
SONIC_LEAF2_NAME ?= leaf2
SONIC_HOST1_NAME ?= host1
SONIC_HOST2_NAME ?= host2
SONIC_SPINE_AS ?= 65000
SONIC_LEAF_AS ?= 65001

# SONiC Image Preparation
SONIC_BRANCH ?= 202505
SONIC_IMAGE_NAME ?= docker-sonic-vs
SONIC_IMAGE_TAG ?= $(SONIC_BRANCH)
SONIC_REGISTRY ?= quay.io/bjozsa-redhat
SONIC_FULL_IMAGE ?= $(SONIC_REGISTRY)/$(SONIC_IMAGE_NAME):$(SONIC_IMAGE_TAG)
SONIC_CONTAINER_ENGINE ?= podman
SONIC_DOWNLOAD_URL ?= https://sonic.software
SONIC_ASSETS_DIR ?= labs/demo-cl-sonic-01/assets

# =============================================================================
# INTERNAL VARIABLES
# =============================================================================
# These are computed variables - do not modify

LAB_DIR ?= labs/$(LAB)
LAB_SCRIPTS = $(LAB_DIR)/deploy.sh $(LAB_DIR)/configure.sh $(LAB_DIR)/test.sh $(LAB_DIR)/status.sh

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate that LAB variable is set
define validate-lab
	@if [ -z "$(LAB)" ]; then \
		echo "!! Error: LAB variable is required"; \
		echo "   Usage: make $@ LAB=lab-name"; \
		echo "   Available labs: $$(ls -1 labs/ 2>/dev/null | tr '\n' ' ')"; \
		exit 1; \
	fi
	@if [ ! -d "$(LAB_DIR)" ]; then \
		echo "!! Error: Lab directory '$(LAB_DIR)' not found"; \
		echo "   Available labs: $$(ls -1 labs/ 2>/dev/null | tr '\n' ' ')"; \
		exit 1; \
	fi
endef

# Validate that required lab scripts exist
define validate-lab-scripts
	@for script in $(LAB_SCRIPTS); do \
		if [ ! -f "$$script" ]; then \
			echo "!! Error: Required script '$$script' not found"; \
			echo "   Each lab must include: deploy.sh, configure.sh, test.sh, status.sh"; \
			exit 1; \
		fi; \
	done
endef

# =============================================================================
# CLABERNETES DEPLOYMENT TARGETS
# =============================================================================

.PHONY: deploy-containerlab destroy-containerlab status-containerlab

deploy-containerlab: ## Deploy Clabernetes only
	@echo ">> Deploying Clabernetes..."
	@echo "   Namespace: $(NS_MGR)"
	@echo "   Release: $(RELEASE)"
	@echo "   Version: $(VERSION)"
	@echo "   UI: https://$(HOST_UI)"
	@oc get ns $(NS_MGR) >/dev/null 2>&1 || oc new-project $(NS_MGR) >/dev/null
	@helm upgrade --install $(RELEASE) $(CHART) \
		--namespace $(NS_MGR) --create-namespace $(VERSION:+--version $(VERSION)) \
		--set manager.replicaCount=1 \
		--set manager.managerLogLevel=info \
		--set manager.controllerLogLevel=info
	@oc -n $(NS_MGR) create configmap clabernetes-config --from-literal=host_ui=$(HOST_UI) --dry-run=client -o yaml | oc apply -f -
	@kustomize build containerlab | oc -n $(NS_MGR) apply -f -
	@oc -n $(NS_MGR) patch deploy/clabernetes-manager --type=json -p='[{"op":"add","path":"/spec/template/spec/securityContext","value":{"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}},{"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"webhook-certs","secret":{"secretName":"clabernetes-manager-webhook-tls"}}]},{"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"webhook-certs","mountPath":"/clabernetes/certificates/webhook","readOnly":true}]}]'
	@echo ">> Waiting for deployments to be ready..."
	@oc -n $(NS_MGR) rollout status deploy/clabernetes-manager --timeout=$(DEPLOYMENT_TIMEOUT)m
	@oc -n $(NS_MGR) rollout status deploy/clabernetes-ui --timeout=$(DEPLOYMENT_TIMEOUT)m
	@echo ">> Clabernetes deployment completed!"
	@echo "   UI: https://$(HOST_UI)"

destroy-containerlab: ## Clean up Clabernetes only
	@echo ">> Cleaning up Clabernetes..."
	@echo "   Checking for existing Helm release..."
	@if helm list -n $(NS_MGR) | grep -q $(RELEASE); then \
		echo "   Found Helm release, uninstalling..."; \
		helm uninstall $(RELEASE) -n $(NS_MGR) || echo "   Warning: Helm uninstall failed, forcing cleanup..."; \
	else \
		echo "   No Helm release found"; \
	fi
	@echo "   Cleaning up any remaining resources..."
	@oc -n $(NS_MGR) delete -k containerlab --ignore-not-found || true
	@oc delete ns $(NS_MGR) --ignore-not-found || true
	@echo "   Waiting for namespace deletion..."
	@oc wait --for=delete namespace/$(NS_MGR) --timeout=60s 2>/dev/null || echo "   Namespace deletion completed or timed out"
	@echo ">> Clabernetes cleanup completed!"

status-containerlab: ## Show Clabernetes status
	@echo ">> Clabernetes Status:"
	@echo "   Namespace: $(NS_MGR)"
	@oc get pods -n $(NS_MGR) -o wide 2>/dev/null || echo "   No pods found"
	@echo "   UI: https://$(HOST_UI)"

# =============================================================================
# LAB MANAGEMENT TARGETS
# =============================================================================

.PHONY: deploy-lab configure-lab test-lab status-lab destroy-lab deploy-all destroy-all

prep-lab: ## Prepare a custom lab (download images, build containers, etc.)
	$(call validate-lab)
	@echo ">> Preparing lab: $(LAB)"
	@echo "   Lab directory: $(LAB_DIR)"
	@if [ -f "$(LAB_DIR)/prep.sh" ]; then \
		cd $(LAB_DIR) && ./prep.sh; \
	else \
		echo "   No prep.sh script found for this lab"; \
	fi

deploy-lab: ## Deploy a custom lab (use LAB=lab-name)
	$(call validate-lab)
	$(call validate-lab-scripts)
	@echo ">> Deploying lab: $(LAB)"
	@echo "   Lab directory: $(LAB_DIR)"
	@cd $(LAB_DIR) && ./deploy.sh

configure-lab: ## Configure a custom lab (use LAB=lab-name)
	$(call validate-lab)
	$(call validate-lab-scripts)
	@echo ">> Configuring lab: $(LAB)"
	@cd $(LAB_DIR) && ./configure.sh

test-lab: ## Test a custom lab (use LAB=lab-name)
	$(call validate-lab)
	$(call validate-lab-scripts)
	@echo ">> Testing lab: $(LAB)"
	@cd $(LAB_DIR) && ./test.sh

status-lab: ## Show custom lab status (use LAB=lab-name)
	$(call validate-lab)
	$(call validate-lab-scripts)
	@echo ">> Lab status: $(LAB)"
	@cd $(LAB_DIR) && ./status.sh

destroy-lab: ## Clean up custom lab (use LAB=lab-name)
	$(call validate-lab)
	$(call validate-lab-scripts)
	@echo ">> Cleaning up lab: $(LAB)"
	@cd $(LAB_DIR) && ./destroy.sh

deploy-all: ## Deploy Clabernetes + custom lab (use LAB=lab-name)
	@$(MAKE) deploy-containerlab
	@$(MAKE) deploy-lab LAB=$(LAB)

destroy-all: ## Clean up everything (use LAB=lab-name)
	@echo ">> Starting complete cleanup of lab and Clabernetes..."
	@echo "   Lab: $(LAB)"
	@echo "   Clabernetes namespace: $(NS_MGR)"
	@echo ""
	@echo ">> Step 1: Cleaning up lab resources..."
	@$(MAKE) destroy-lab LAB=$(LAB) || echo "   Warning: Lab cleanup had issues, continuing..."
	@echo ""
	@echo ">> Step 2: Cleaning up Clabernetes..."
	@$(MAKE) destroy-containerlab
	@echo ""
	@echo ">> Complete cleanup finished!"
	@echo "   Note: If you see warnings above, some resources may need manual cleanup"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

.PHONY: help list-labs clean

help: ## Show this help message
	@echo "Clabernetes on OpenShift - Available Commands"
	@echo "============================================="
	@echo ""
	@echo "Configuration:"
	@echo "  OCP_DOMAIN=$(OCP_DOMAIN)"
	@echo "  NS_MGR=$(NS_MGR)"
	@echo "  LAB=$(LAB)"
	@echo ""
	@echo "Available Commands:"
	@echo "  Clabernetes Management:"
	@echo "    make deploy-containerlab     # Deploy only Clabernetes"
	@echo "    make destroy-containerlab    # Clean up only Clabernetes"
	@echo "    make status-containerlab     # Show Clabernetes status"
	@echo ""
	@echo "  Lab Management:"
	@echo "    make prep-lab LAB=my-lab     # Prepare lab (download images, etc.)"
	@echo "    make deploy-lab LAB=my-lab   # Deploy only the lab"
	@echo "    make configure-lab LAB=my-lab # Configure the lab"
	@echo "    make test-lab LAB=my-lab     # Test the lab"
	@echo "    make status-lab LAB=my-lab   # Show lab status"
	@echo "    make destroy-lab LAB=my-lab  # Clean up lab"
	@echo ""
	@echo "  Combined Operations:"
	@echo "    make deploy-all LAB=my-lab   # Deploy Clabernetes + lab"
	@echo "    make destroy-all LAB=my-lab  # Clean up everything"
	@echo ""
	@echo "  Utilities:"
	@echo "    make list-labs               # List available labs"
	@echo "    make help                    # Show this help message"
	@echo ""
		@echo "Examples:"
	@echo "  make deploy-containerlab       # Deploy only Clabernetes"
	@echo "  make deploy-lab LAB=demo-cl-frr-01 # Deploy FRR BGP lab"
	@echo "  make deploy-lab LAB=demo-cl-sonic-01 # Deploy SONiC spine-leaf lab"
	@echo "  make deploy-all LAB=demo-cl-frr-01 # Deploy everything (FRR)"
	@echo "  make deploy-all LAB=demo-cl-sonic-01 # Deploy everything (SONiC)"
	@echo "  make test-lab LAB=demo-cl-frr-01  # Test FRR lab"
	@echo "  make test-lab LAB=demo-cl-sonic-01  # Test SONiC lab"
	@echo "  make destroy-all LAB=demo-cl-frr-01 # Clean up everything (FRR)"
	@echo "  make destroy-all LAB=demo-cl-sonic-01 # Clean up everything (SONiC)"

list-labs: ## List available labs
	@echo "Available labs:"
	@if [ -d "labs" ]; then \
		for lab in labs/*/; do \
			if [ -d "$$lab" ]; then \
				lab_name=$$(basename "$$lab"); \
				echo "  $$lab_name"; \
			fi; \
		done; \
	else \
		echo "  No labs directory found"; \
	fi

clean: ## Clean up temporary files
	@echo ">> Cleaning up temporary files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true

# =============================================================================
# LEGACY TARGETS (for backward compatibility)
# =============================================================================

.PHONY: deploy destroy status test

deploy: deploy-all ## Legacy: Deploy Clabernetes + default lab
	@echo ">> Note: Using legacy 'deploy' target. Consider using 'deploy-all LAB=lab-name'"

destroy: destroy-all ## Legacy: Clean up everything
	@echo ">> Note: Using legacy 'destroy' target. Consider using 'destroy-all LAB=lab-name'"

status: status-containerlab ## Legacy: Show Clabernetes status
	@echo ">> Note: Using legacy 'status' target. Consider using 'status-containerlab' or 'status-lab LAB=lab-name'"

test: test-lab ## Legacy: Test default lab
	@echo ">> Note: Using legacy 'test' target. Consider using 'test-lab LAB=lab-name'"

# =============================================================================
# DEFAULT TARGET
# =============================================================================

.DEFAULT_GOAL := help
