# LAB-Automated-Test

This directory contains all automated testing scripts for the InfamousLab infrastructure, including Wazuh SIEM, Cloudflare Zero Trust, and AWS resources.

## 🚀 Quick Start

### Run All Tests (Recommended)
```bash
cd LAB-Automated-Test
./run_all_tests.sh comprehensive
```

### Run Specific Test Categories
```bash
./run_all_tests.sh quick         # Basic tests (~2 minutes)
./run_all_tests.sh standard      # Standard tests (~5 minutes) 
./run_all_tests.sh comprehensive # Full validation (~10 minutes)
./run_all_tests.sh full         # Complete suite (~15 minutes)
```

### Run Individual Tests
```bash
./run_all_tests.sh master-comprehensive  # Most comprehensive single test
./run_all_tests.sh cloudflare-tunnel    # Just Cloudflare tests
./run_all_tests.sh wazuh-basic          # Basic Wazuh connectivity
```

## 📋 Available Test Scripts

### 🎯 Primary Test Scripts

| Script | Purpose | Duration | Scope |
|--------|---------|----------|-------|
| `master_consolidated_test.sh` | **Complete infrastructure validation** | ~2-15 min | Everything |
| `run_all_tests.sh` | **Centralized test runner** | Variable | All scripts |
| `web_launcher.sh` | **Web interface launcher** | Instant | Dashboard API |

### 🔧 Component-Specific Tests

| Script | Purpose | Duration | Focus Area |
|--------|---------|----------|-----------|
| `aws_environment_check.sh` | AWS credentials and region validation | ~1 min | AWS Setup |
| `aws_configure_helper.sh` | AWS configuration assistance | ~1 min | AWS Config |
| `cloudflare_tunnel_health_check.sh` | Cloudflare tunnel connectivity | ~2 min | Cloudflare |
| `tunnel_status_check.sh` | Tunnel status and DNS resolution | ~1 min | Networking |
| `wazuh_basic_health_check.sh` | Basic Wazuh connectivity | ~2 min | Wazuh |
| `automated_health_check.sh` | Automated infrastructure checks | ~5 min | General |
| `infrastructure_monitoring.sh` | Infrastructure monitoring checks | ~3 min | Monitoring |

### 🛠️ Utility Scripts

| Script | Purpose | Notes |
|--------|---------|-------|
| `infrastructure_monitoring copy.sh` | Backup of monitoring script | Archive |

## 🧪 Test Categories

### Quick Tests (~2 minutes)
- Prerequisites validation
- AWS configuration check
- Basic Cloudflare tunnel test
- Basic Wazuh connectivity

### Standard Tests (~5 minutes)
- All quick tests
- Tunnel status validation
- Automated health checks

### Comprehensive Tests (~10 minutes)
- All standard tests
- Full infrastructure validation
- Security compliance checks
- Performance monitoring

### Full Test Suite (~15 minutes)
- All comprehensive tests
- Master comprehensive validation
- Detailed reporting
- Complete environment verification

## 📊 Output and Reports

### Log Files
All test runs generate logs in `test-logs/` directory:
- `test_runner_TIMESTAMP.log` - Main runner log
- `TESTNAME_TIMESTAMP.log` - Individual test logs

### Reports
Test reports are saved in `test-reports/` directory:
- HTML reports with interactive dashboards
- JSON reports for programmatic access
- Markdown summaries for documentation

### Example Report Locations
```
test-reports/
├── master_test_report_20250727_143022.html
├── master_test_report_20250727_143022.json
├── infrastructure_health_report_20250727_143022.html
└── test_summary_20250727_143022.md
```

## 🔍 Test Coverage

### Infrastructure Components
- ✅ **AWS EC2 Instances** - All 7 Wazuh instances
- ✅ **VPC and Networking** - Subnets, security groups, NAT gateways
- ✅ **Load Balancers** - ALBs and NLBs for all services
- ✅ **EBS Volumes** - Hot and cold storage validation
- ✅ **Security Groups** - Proper access control validation

### Cloudflare Components  
- ✅ **Zero Trust Tunnel** - Connectivity and SSL validation
- ✅ **DNS Resolution** - Domain and subdomain checks
- ✅ **Access Policies** - WARP device validation
- ✅ **Security Headers** - Cloudflare proxy validation

### Wazuh Application
- ✅ **Dashboard Access** - Web interface availability
- ✅ **Service Health** - Individual service endpoints
- ✅ **Manager Nodes** - 2 manager instances
- ✅ **Indexer Nodes** - 3 indexer instances with hot/cold storage
- ✅ **Dashboard Nodes** - 2 dashboard instances

### Security & Compliance
- ✅ **SSH Access Control** - No open SSH to internet
- ✅ **EBS Encryption** - All volumes encrypted
- ✅ **SSL/TLS Validation** - Certificate verification
- ✅ **Access Policies** - Zero Trust configuration

### Performance & Monitoring
- ✅ **Response Times** - Application performance
- ✅ **CloudWatch Metrics** - AWS monitoring
- ✅ **Health Endpoints** - Service availability
- ✅ **Target Group Health** - Load balancer validation

## 🛠️ Prerequisites

### Required Tools
```bash
# AWS CLI
aws --version

# Terraform (for infrastructure validation)
terraform --version

# Basic networking tools
curl --version
nslookup --version

# JSON processing
jq --version

# SSL tools
openssl version
```

### Required Credentials
- **AWS CLI configured** with appropriate permissions
- **AWS region set** to `eu-west-2`
- **Internet connectivity** for Cloudflare tests

### Environment Variables
```bash
export AWS_REGION=eu-west-2
export AWS_PROFILE=your-profile  # if using profiles
```

## 📖 Usage Examples

### 1. First-Time Setup Validation
```bash
# Run comprehensive tests after initial deployment
./run_all_tests.sh comprehensive

# Check the HTML report
open test-reports/master_test_report_*.html
```

### 2. Daily Health Checks
```bash
# Quick daily validation
./run_all_tests.sh quick

# Review any warnings
cat test-logs/test_runner_*.log | grep "⚠️"
```

### 3. Troubleshooting Issues
```bash
# Run specific component tests
./run_all_tests.sh cloudflare-tunnel
./run_all_tests.sh wazuh-basic

# Check detailed logs
tail -f test-logs/cloudflare-tunnel_*.log
```

### 4. Pre-Production Validation
```bash
# Full test suite before changes
./run_all_tests.sh full

# Generate detailed reports
ls -la test-reports/
```

### 5. Continuous Integration
```bash
# Automated testing (exit codes)
./run_all_tests.sh standard
echo "Exit code: $?"  # 0=success, 1=warnings, 2=failures
```

## 🎯 Success Criteria

### Excellent Health (95%+ pass rate)
- All infrastructure components operational
- Sub-3 second response times
- All security policies enforced
- Complete monitoring coverage

### Good Health (85-94% pass rate)
- Minor startup delays acceptable
- Some services may be initializing
- Non-critical warnings present

### Poor Health (<85% pass rate)
- Significant infrastructure issues
- Multiple component failures
- Immediate attention required

## 🔧 Customization

### Adding New Tests
1. Create script in this directory
2. Make it executable: `chmod +x new_test.sh`
3. Add to `TEST_SCRIPTS` array in `run_all_tests.sh`
4. Add to appropriate test category

### Modifying Test Categories
Edit the `TEST_CATEGORIES` array in `run_all_tests.sh`:
```bash
declare -A TEST_CATEGORIES=(
    ["custom"]="prerequisites new-test cloudflare-tunnel"
)
```

### Environment-Specific Configuration
Modify variables at the top of test scripts:
```bash
AWS_REGION="your-region"
TUNNEL_URL="https://your-domain.com"
```

## 🚨 Troubleshooting

### Common Issues

#### AWS Permission Errors
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify region
aws configure get region
```

#### Cloudflare Connectivity Issues
```bash
# Test DNS resolution
nslookup wazuh.reddomelab.space 1.1.1.1

# Test direct connectivity
curl -I https://wazuh.reddomelab.space
```

#### Script Permission Issues
```bash
# Fix all script permissions
chmod +x *.sh
```

### Getting Help

1. **Check logs** in `test-logs/` directory
2. **Review HTML reports** for detailed diagnostics
3. **Run individual tests** to isolate issues
4. **Check AWS Console** for infrastructure status
5. **Verify Cloudflare Dashboard** for tunnel status

## 📞 Support

For issues with the testing infrastructure:

1. Check recent logs for error details
2. Verify AWS and Cloudflare credentials
3. Ensure all prerequisites are installed
4. Review the specific test script source code
5. Run tests with verbose output: `./run_all_tests.sh -v comprehensive`

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Run comprehensive tests
- **Daily**: Run quick tests  
- **After changes**: Run full test suite
- **Monthly**: Review and archive old logs

### Log Cleanup
```bash
# Clean old logs (older than 30 days)
find test-logs/ -name "*.log" -mtime +30 -delete
find test-reports/ -name "*.*" -mtime +30 -delete
```

---

**Last Updated**: July 27, 2025  
**Version**: 1.0  
**Maintainer**: InfamousLab Infrastructure Team
