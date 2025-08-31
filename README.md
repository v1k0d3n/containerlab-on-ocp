# Containerlab/Clabernetes on OpenShift

A simple, modular demonstration of running Containerlab network topologies on OpenShift using Containerlab (Clabernetes). This project showcases enterprise networking architectures in a Kubernetes-native environment.

## **Project Architecture**

```
containerlab-on-ocp/
├── Makefile                    # Centralized automation & configuration
├── README.md                   # Project documentation (this file)
├── containerlab/               # OpenShift-specific Containerlab/clabernetes configs
│   ├── kustomization.yaml      # Kustomize configuration
│   ├── config.yaml             # ConfigMap for host UI
│   ├── route-ui.yaml           # UI route configuration
│   ├── svc-ui-http.yaml        # UI HTTP service
│   └── svc-manager.yaml        # Manager service
└── labs/                       # Modular lab environments
    ├── demo-cl-frr-01/         # FRR BGP demo lab
    │   ├── deploy.sh           # Lab deployment
    │   ├── configure.sh        # Lab configuration
    │   ├── test.sh             # Lab testing
    │   ├── status.sh           # Lab status
    │   ├── destroy.sh          # Lab cleanup
    │   ├── topology.yaml       # Containerlab topology
    │   └── README.md           # Lab documentation
    └── demo-cl-sonic-01/       # SONiC spine-leaf lab
        ├── prep.sh             # Load SONiC OS to custom registry
        ├── deploy.sh           # Lab deployment
        ├── configure.sh        # Lab configuration
        ├── test.sh             # Lab testing
        ├── status.sh           # Lab status
        ├── destroy.sh          # Lab cleanup
        ├── topology.yaml       # Containerlab topology
        └── README.md           # Lab documentation
```

## **What This Project Provides**

### **Modular Lab Management**
- **Independent Labs**: Each lab is self-contained with its own configuration
- **Consistent Interface**: All labs follow the same script structure
- **Easy Extension**: Add new labs by following the established pattern
- **Isolated Testing**: Test different network architectures independently

### **Automated Deployment**
- **One-Command Setup**: Deploy entire environments with single commands
- **Intelligent Dependencies**: Automatically handles Containerlab/Clabernetes deployment first
- **Validation**: Built-in checks ensure proper deployment order
- **Cleanup**: Complete environment teardown with single commands

### **Enterprise Networking**
- **Production Architectures**: Real-world network designs (spine-leaf, BGP peering)
- **Open Source Tools**: FRR, SONiC, and other industry-standard networking software
- **Kubernetes Native**: Runs seamlessly on OpenShift with proper RBAC and security

## **How to Use This Project**

### **Prerequisites**
- OpenShift cluster with admin access
- `oc` CLI tool configured
- `make` command available
- Internet access for container images

### **Quick Start**

#### **1. Deploy Everything at Once**
```bash
# Deploy Containerlab/clabernetes + a specific lab
make deploy-all LAB=demo-cl-frr-01        # FRR BGP lab
make deploy-all LAB=demo-cl-sonic-01      # Spine-leaf lab
```

#### **2. Step-by-Step Deployment**
```bash
# Step 1: Deploy Containerlab/clabernetes infrastructure
make deploy-containerlab

# Step 2: Deploy a specific lab
make deploy-lab LAB=demo-cl-frr-01

# Step 3: Configure the lab
make configure-lab LAB=demo-cl-frr-01

# Step 4: Test the lab
make test-lab LAB=demo-cl-frr-01
```

#### **3. Lab Management**
```bash
# Check lab status
make status-lab LAB=demo-cl-frr-01

# Test lab connectivity
make test-lab LAB=demo-cl-frr-01

# Clean up specific lab
make destroy-lab LAB=demo-cl-frr-01

# Clean up everything
make destroy-all LAB=demo-cl-frr-01
```

### **Available Labs**

#### **demo-cl-frr-01: FRR BGP Lab**
- **Purpose**: Simple BGP peering between two routers
- **Architecture**: Point-to-point BGP with route advertisement
- **Use Case**: Learning BGP fundamentals, testing route propagation

#### **demo-cl-sonic-01: Spine-Leaf Lab**
- **Purpose**: Traditional data center network architecture
- **Architecture**: 2x spine + 2x leaf + 2x host topology
- **Use Case**: Enterprise networking, high-availability design, BGP EVPN

## **Makefile Features**

### **Smart Automation**
- **Dependency Management**: Ensures Containerlab/clabernetes is deployed before labs
- **Variable Inheritance**: Labs inherit configuration from main Makefile
- **Validation**: Checks for required tools and configurations
- **Error Handling**: Graceful failure with helpful error messages

### **Comprehensive Commands**
```bash
make help                    # Show all available commands
make deploy-containerlab     # Deploy only Containerlab/clabernetes
make prep-lab LAB=name       # Prepare lab (download images, etc.)
make deploy-lab LAB=name     # Deploy specific lab
make deploy-all LAB=name     # Deploy everything
make configure-lab LAB=name  # Configure deployed lab
make test-lab LAB=name       # Test lab functionality
make status-lab LAB=name     # Show lab status
make destroy-lab LAB=name    # Remove specific lab
make destroy-containerlab    # Remove Containerlab/clabernetes
make destroy-all LAB=name    # Remove everything
```

### **Configuration Management**
- **Centralized Variables**: All configuration in one place
- **Environment Override**: Easy to customize for different environments
- **Lab-Specific Settings**: Each lab can have custom configurations
- **Consistent Naming**: Standardized variable names across all labs

## **Features**

### **Security & Compliance**
- **OpenShift SCCs**: Proper security context constraints
- **RBAC**: Role-based access control for all components
- **Network Policies**: Isolated network segments
- **Privilege Management**: Minimal required privileges

### **Scalability & Reliability**
- **Horizontal Scaling**: Easy to add more lab instances
- **Resource Management**: Configurable CPU/memory limits
- **Health Monitoring**: Built-in status checking
- **Graceful Degradation**: Proper error handling and recovery

### **Operations & Maintenance**
- **Logging**: Comprehensive logging for troubleshooting
- **Monitoring**: Built-in health checks and status reporting
- **Backup/Restore**: Easy environment recreation
- **Documentation**: Detailed README files for each component

## **Learning & Development**

### **Educational Value**
- **Network Architecture**: Real-world network designs
- **Kubernetes Networking**: Understanding container networking
- **BGP & Routing**: Industry-standard routing protocols
- **DevOps Practices**: Infrastructure as Code principles

### **Development Workflow**
- **Rapid Prototyping**: Quick lab creation and testing
- **Iterative Development**: Easy to modify and retest
- **Version Control**: All configurations in Git
- **Collaboration**: Shareable lab environments

## **Getting Started**

### **1. Clone the Repository**
```bash
git clone <repository-url>
cd containerlab-on-ocp
```

### **2. Review Configuration**
```bash
# Check the Makefile variables
make help

# Review lab-specific configurations
cat labs/demo-cl-frr-01/README.md
cat labs/demo-cl-sonic-01/README.md
```

### **3. Deploy Your First Lab**
```bash
# Start with the simple FRR BGP lab
make deploy-all LAB=demo-cl-frr-01

# Or try the spine-leaf architecture
make deploy-all LAB=demo-cl-sonic-01
```

### **4. Explore and Learn**
```bash
# Check what's running
make status-lab LAB=demo-cl-frr-01

# Test connectivity
make test-lab LAB=demo-cl-frr-01

# View logs and troubleshoot
oc logs -n demo-cl-frr-01 <pod-name>
```

## **Contributing**

### **Adding New Labs**
1. **Create Lab Directory**: `labs/your-lab-name/`
2. **Follow Script Pattern**: `deploy.sh`, `configure.sh`, `test.sh`, `status.sh`, `destroy.sh`
3. **Add Topology**: Create `topology.yaml` for Containerlab
4. **Document**: Write comprehensive `README.md`
5. **Update Makefile**: Add lab-specific variables if needed

### **Improving Existing Labs**
- **Enhance Testing**: Add more comprehensive test scenarios
- **Optimize Configuration**: Improve startup times and reliability
- **Add Monitoring**: Include health checks and metrics
- **Expand Documentation**: Add troubleshooting guides and examples

## **Support & Troubleshooting**

### **Common Issues**
- **Pod Startup Failures**: Check SCCs and resource limits
- **Network Connectivity**: Verify IP addressing and routing
- **BGP Issues**: Check neighbor configurations and AS numbers
- **Permission Errors**: Ensure proper RBAC and SCCs

### **Getting Help**
- **Check Logs**: Use `oc logs` to view detailed error messages
- **Verify Status**: Run `make status-lab` to check component health
- **Review Configuration**: Ensure all variables are set correctly
- **Check Documentation**: Each lab has detailed troubleshooting guides

## **Why This Project?**

### **Industry Relevance**
- **Modern Networking**: Uses current industry-standard tools and protocols
- **Cloud Native**: Designed for Kubernetes/OpenShift environments
- **Enterprise Testing**: Test various architectures and configurations before going to production
- **Open Source**: Built with widely-adopted open source components

### **Technical Excellence**
- **Modular Design**: Easy to extend and maintain
- **Automation First**: Minimal manual intervention required
- **Best Practices**: Follows Kubernetes and networking best practices
- **Documentation**: Comprehensive guides and examples

### **Learning Value**
- **Hands-On Experience**: Real network topologies to experiment with
- **Industry Skills**: Learn technologies used in production environments
- **DevOps Integration**: Understand infrastructure automation
- **Troubleshooting**: Develop real-world problem-solving skills

---

**Ready to build enterprise networks on OpenShift? Start with `make help` to see all available options!**
