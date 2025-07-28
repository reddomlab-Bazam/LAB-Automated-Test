# 🧪 InfamousLab Consolidated Testing Suite

## 📋 Complete Test Infrastructure Overview

All testing scripts have been consolidated and organized in the `LAB-Automated-Test` directory with both command-line and HTML dashboard interfaces.

## 🎯 Main Components

### 1. **HTML Dashboard** (`infrastructure_testing_dashboard.html`)
- **Interactive web interface** for all testing operations
- **Real-time status monitoring** with visual indicators
- **Test execution controls** with progress tracking
- **Report viewing** and download capabilities
- **Script management** with code viewing and execution
- **Responsive design** for desktop and mobile

### 2. **Master Consolidated Script** (`master_consolidated_test.sh`)
- **All-in-one testing solution** combining every test category
- **Four test levels**: Quick (2m), Standard (5m), Comprehensive (10m), Full (15m)
- **Comprehensive reporting** in both JSON and HTML formats
- **Complete infrastructure validation** for Wazuh + Cloudflare + AWS
- **Security compliance checks** and performance monitoring

### 3. **Centralized Test Runner** (`run_all_tests.sh`)
- **Unified interface** for executing all individual test scripts
- **Category-based testing** with flexible execution options
- **Logging and reporting** with detailed output
- **Dry-run capabilities** for testing execution plans

### 4. **Web Interface Launcher** (`web_launcher.sh`)
- **CGI-compatible script** for web server integration
- **JSON API responses** for web dashboard communication
- **Test execution management** with status reporting
- **Report retrieval** and status monitoring

## 📊 Available Test Categories

| Category | Duration | Coverage | Use Case |
|----------|----------|----------|-----------|
| **Quick** | ~2 minutes | Basic connectivity, credentials, DNS | Daily monitoring, CI/CD |
| **Standard** | ~5 minutes | Infrastructure components, load balancers | Weekly validation |
| **Comprehensive** | ~10 minutes | Full validation, security, performance | Pre-production |
| **Full** | ~15 minutes | Complete suite, all scripts, detailed reporting | Monthly audits |

## 🛠️ Individual Test Scripts

### Core Infrastructure Tests
- `aws_environment_check.sh` - AWS credentials and region validation
- `aws_configure_helper.sh` - AWS configuration assistance
- `cloudflare_tunnel_health_check.sh` - Cloudflare tunnel connectivity
- `tunnel_status_check.sh` - DNS resolution and tunnel status
- `wazuh_basic_health_check.sh` - Basic Wazuh SIEM connectivity

### Comprehensive Health Checks
- `automated_health_check.sh` - Automated infrastructure monitoring
- `comprehensive_health_check.sh` - Full health check with HTML reports
- `infrastructure_monitoring.sh` - Performance and monitoring validation

### Utility Scripts
- `web_launcher.sh` - Web interface integration script

## 🚀 Quick Start Guide

### 1. **Open HTML Dashboard**
```bash
# Open in your browser
open /Users/bazamchekrian/Desktop/InfamousLAB/LAB-Automated-Test/infrastructure_testing_dashboard.html
```

### 2. **Run Quick Tests** (Command Line)
```bash
cd /Users/bazamchekrian/Desktop/InfamousLAB/LAB-Automated-Test
./master_consolidated_test.sh quick
```

### 3. **Run Comprehensive Tests**
```bash
./master_consolidated_test.sh comprehensive
```

### 4. **Use Centralized Runner**
```bash
./run_all_tests.sh --list                    # List all available tests
./run_all_tests.sh quick                     # Run quick test category
./run_all_tests.sh master-comprehensive     # Run specific test
```

## 📈 Reporting and Output

### Generated Reports
All tests generate comprehensive reports in multiple formats:

#### HTML Reports (Interactive)
- **Dashboard-style layout** with visual indicators
- **Clickable links** to external resources
- **Color-coded results** for easy scanning
- **Responsive design** for all devices

#### JSON Reports (API-friendly)
- **Structured data** for programmatic processing
- **Complete test results** with timestamps
- **Success rates** and failure analysis
- **Integration-ready format**

#### Terminal Output (Real-time)
- **Color-coded console output** with emoji indicators
- **Progress tracking** with real-time updates
- **Detailed logging** with timestamps
- **Summary statistics** and recommendations

### Report Locations
```
LAB-Automated-Test/
├── test-reports/
│   ├── consolidated_test_report_TIMESTAMP.html
│   ├── consolidated_test_report_TIMESTAMP.json
│   ├── master_test_report_TIMESTAMP.html
│   └── infrastructure_health_report_TIMESTAMP.html
└── test-logs/
    ├── master_test_TIMESTAMP.log
    ├── test_runner_TIMESTAMP.log
    └── individual_test_TIMESTAMP.log
```

## 🎯 Test Coverage

### ✅ **Infrastructure Components**
- **AWS EC2 Instances** - All 7 Wazuh nodes (2 managers, 3 indexers, 2 dashboards)
- **VPC and Networking** - Subnets, NAT gateways, route tables
- **Load Balancers** - ALBs and NLBs with health checks
- **Security Groups** - Proper access control validation
- **EBS Volumes** - Hot and cold storage with encryption

### ✅ **Cloudflare Zero Trust**
- **Tunnel Connectivity** - End-to-end tunnel validation
- **DNS Resolution** - Domain and subdomain checks
- **SSL/TLS Certificates** - Certificate validity and chain
- **Access Policies** - WARP device requirements
- **Security Headers** - Cloudflare proxy validation

### ✅ **Wazuh SIEM Application**
- **Dashboard Access** - Web interface availability through tunnel
- **Service Health** - Individual component health endpoints
- **Manager Nodes** - 2 manager instances with API validation
- **Indexer Cluster** - 3-node cluster with hot/cold storage
- **Dashboard Nodes** - 2 dashboard instances with load balancing

### ✅ **Security & Compliance**
- **SSH Access Control** - No public SSH access validation
- **EBS Encryption** - All volumes encrypted at rest
- **Network Security** - Security group rule validation
- **Zero Trust Policies** - Access control verification

### ✅ **Performance & Monitoring**
- **Response Times** - Application performance metrics
- **Health Endpoints** - Service availability monitoring
- **CloudWatch Integration** - AWS monitoring validation
- **Load Balancer Health** - Target group status

## 🔧 Customization Options

### Environment Variables
```bash
export AWS_REGION=eu-west-2                    # AWS region
export TUNNEL_URL=https://wazuh.reddomelab.space # Cloudflare tunnel URL
```

### Adding Custom Tests
1. Create new script in `LAB-Automated-Test/`
2. Make executable: `chmod +x new_test.sh`
3. Add to `run_all_tests.sh` test arrays
4. Update HTML dashboard script list

### Report Customization
- Modify CSS in HTML dashboard for styling
- Adjust JSON structure in master script
- Add custom metrics and validation

## 📞 Usage Examples

### Daily Monitoring
```bash
# Quick health check (automated)
./master_consolidated_test.sh quick --json-only

# Check specific component
./run_all_tests.sh cloudflare-tunnel
```

### Weekly Validation
```bash
# Standard test suite
./master_consolidated_test.sh standard

# Open HTML report
open test-reports/consolidated_test_report_*.html
```

### Pre-Production Validation
```bash
# Full comprehensive testing
./master_consolidated_test.sh full

# Review all reports
ls -la test-reports/
```

### Continuous Integration
```bash
# Return exit codes for automation
./master_consolidated_test.sh standard
echo "Exit code: $?"  # 0=success, 1=warnings, 2=critical
```

## 🚨 Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| `0` | Success | All tests passed |
| `1` | Warnings | Some tests failed, investigate |
| `2` | Critical | Critical failures, immediate attention |

## 📋 File Inventory

### Current LAB-Automated-Test Directory
```
LAB-Automated-Test/
├── infrastructure_testing_dashboard.html      # 🎯 MAIN HTML DASHBOARD
├── master_consolidated_test.sh                # 🎯 MAIN CONSOLIDATED SCRIPT
├── run_all_tests.sh                          # 🎯 CENTRALIZED RUNNER
├── web_launcher.sh                           # 🎯 WEB INTERFACE LAUNCHER
├── README.md                                 # Complete documentation
├── QUICK_REFERENCE.md                        # Quick command reference
├── comprehensive_health_check.sh             # Existing comprehensive test
├── automated_health_check.sh                 # Existing automated test
├── aws_environment_check.sh                  # AWS validation
├── aws_configure_helper.sh                   # AWS configuration
├── cloudflare_tunnel_health_check.sh         # Cloudflare testing
├── tunnel_status_check.sh                    # Tunnel status
├── wazuh_basic_health_check.sh              # Basic Wazuh test
├── infrastructure_monitoring.sh              # Infrastructure monitoring
├── infrastructure_monitoring\ copy.sh        # Backup copy
├── test-logs/                                # Generated logs
├── test-reports/                             # Generated reports
└── .env                                      # Environment configuration
```

## 🎉 Key Features

### ✨ **Unified Interface**
- **Single HTML dashboard** for all operations
- **Consistent command-line interface** across all scripts
- **Standardized reporting** in multiple formats

### ✨ **Comprehensive Coverage**
- **Every infrastructure component** tested
- **Security and compliance** validation
- **Performance monitoring** included

### ✨ **Flexible Execution**
- **Multiple test categories** for different use cases
- **Individual component testing** for troubleshooting
- **Batch execution** for comprehensive validation

### ✨ **Rich Reporting**
- **Interactive HTML dashboards** with visual indicators
- **JSON APIs** for integration
- **Detailed logs** for troubleshooting

### ✨ **Easy Integration**
- **Web-friendly interfaces** for dashboard integration
- **CGI-compatible scripts** for web servers
- **Exit codes** for automation and CI/CD

## 🔄 Maintenance

### Regular Tasks
- **Daily**: Run quick tests for monitoring
- **Weekly**: Execute standard test suite
- **Monthly**: Full comprehensive validation
- **After changes**: Run appropriate test category

### Log Management
```bash
# Clean old logs (>30 days)
find test-logs/ -name "*.log" -mtime +30 -delete
find test-reports/ -name "*.*" -mtime +30 -delete
```

---

## 🎯 **Ready to Use!**

Your complete testing infrastructure is now consolidated and ready. You can:

1. **Open the HTML dashboard** for interactive testing
2. **Run consolidated tests** from command line
3. **Execute individual components** for troubleshooting
4. **Generate comprehensive reports** in multiple formats
5. **Integrate with web interfaces** using the launcher script

**Everything you need is in the `LAB-Automated-Test` directory!**
