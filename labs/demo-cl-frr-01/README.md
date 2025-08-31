# FRR BGP Lab (demo-cl-frr-01)

## 🏗️ **Lab Architecture**

This lab demonstrates a **simple BGP peering setup** between two FRR routers on OpenShift using Clabernetes.

```
┌─────────────────┐    ┌─────────────────┐
│   FRR Router 1  │────│   FRR Router 2  │
│   (AS 65001)    │    │   (AS 65002)    │
│   10.0.0.1      │    │   10.0.0.2      │
└─────────────────┘    └─────────────────┘
         │                       │
         │                       │
    ┌────▼────┐            ┌────▼────┐
    │ eth1    │            │ eth1    │
    │10.35.1.1│            │10.35.1.2│
    └─────────┘            └─────────┘
```

## 🌐 **Network Topology**

### **Router Configuration**
- **FRR Router 1**: AS 65001, Router ID 10.0.0.1
- **FRR Router 2**: AS 65002, Router ID 10.0.0.2

### **Network Segments**
- **Management Network**: 172.20.20.0/24 (eth0)
- **BGP Peering Network**: 10.35.1.0/24 (eth1)
- **Loopback Networks**: 10.0.0.1/32, 10.0.0.2/32

### **BGP Configuration**
- **BGP Version**: 4
- **Address Family**: IPv4 Unicast
- **Route Advertisement**: Loopback networks (10.0.0.1/32, 10.0.0.2/32)
- **Route Policy**: Allow all routes

## 🚀 **Quick Start**

### **Deploy the Lab**
```bash
# Deploy everything (Clabernetes + FRR Lab)
make deploy-all LAB=demo-cl-frr-01

# Or deploy step by step
make deploy-containerlab
make deploy-lab LAB=demo-cl-frr-01
make configure-lab LAB=demo-cl-frr-01
```

### **Test the Lab**
```bash
# Test BGP connectivity
make test-lab LAB=demo-cl-frr-01

# Check lab status
make status-lab LAB=demo-cl-frr-01
```

### **Clean Up**
```bash
# Remove everything
make destroy-all LAB=demo-cl-frr-01

# Or remove step by step
make destroy-lab LAB=demo-cl-frr-01
make destroy-containerlab
```

## 🔧 **What This Lab Demonstrates**

1. **Basic BGP Peering**: Two routers establishing BGP neighbor relationships
2. **Route Advertisement**: Routers advertising their loopback networks
3. **Network Reachability**: End-to-end connectivity across BGP domains
4. **FRR Configuration**: Using FRR routing software in containers
5. **Clabernetes Integration**: Running network topologies on Kubernetes

## 📊 **Expected Results**

After successful deployment and configuration:
- ✅ Both FRR routers should show BGP neighbors in ESTABLISHED state
- ✅ Each router should receive routes from its peer
- ✅ Ping tests between routers should succeed
- ✅ BGP route tables should show advertised networks

## 🎯 **Use Cases**

- **Learning BGP**: Understanding BGP neighbor establishment
- **Network Testing**: Validating BGP route propagation
- **Development**: Testing FRR configurations before production
- **Training**: Teaching BGP concepts in a safe environment

## 📁 **Files in This Lab**

- `topology.yaml` - Containerlab topology definition
- `deploy.sh` - Lab deployment script
- `configure.sh` - BGP configuration script
- `test.sh` - Connectivity testing script
- `status.sh` - Lab status monitoring script
- `destroy.sh` - Lab cleanup script
- `README.md` - This documentation file

## 🔍 **Troubleshooting**

### **Common Issues**
1. **BGP not established**: Check if FRR daemons are running
2. **Routes not advertised**: Verify BGP configuration syntax
3. **Connectivity failures**: Ensure IP addresses are correctly configured

### **Debug Commands**
```bash
# Check BGP status
make status-lab LAB=demo-cl-frr-01

# View FRR logs
oc logs -n demo-cl-frr-01 <pod-name>

# Test connectivity
make test-lab LAB=demo-cl-frr-01
```
