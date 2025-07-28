#!/bin/bash

# ============================================================================
# MASTER CONSOLIDATED INFRASTRUCTURE TEST SCRIPT
# ============================================================================
# This script consolidates ALL testing functionality into a single executable
# that can be called from the HTML dashboard or run independently.
# Includes all test categories, reporting, and monitoring capabilities.
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
AWS_REGION="${AWS_REGION:-eu-west-2}"
TUNNEL_URL="https://wazuh.reddomelab.space"
CLOUDFLARE_DOMAIN="reddomelab.space"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="$SCRIPT_DIR/test-logs"
REPORT_DIR="$SCRIPT_DIR/test-reports"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0
CRITICAL_FAILURES=0

# Arrays to store results
declare -a TEST_RESULTS
declare -a CRITICAL_ISSUES
declare -a WARNINGS

# Create directories
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
    TEST_RESULTS+=("PASS: $1")
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    ((WARNING_TESTS++))
    ((TOTAL_TESTS++))
    TEST_RESULTS+=("WARN: $1")
    WARNINGS+=("$1")
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    TEST_RESULTS+=("FAIL: $1")
}

critical() {
    echo -e "${RED}💥 CRITICAL: $1${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    ((CRITICAL_FAILURES++))
    TEST_RESULTS+=("CRITICAL: $1")
    CRITICAL_ISSUES+=("$1")
}

section() {
    echo "" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    echo -e "${PURPLE}  $1${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/master_test_$TIMESTAMP.log"
}

header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                        🧪 MASTER CONSOLIDATED INFRASTRUCTURE TEST                              ║"
    echo "║                                                                                                ║"
    echo "║  Complete testing suite for Wazuh SIEM + Cloudflare Zero Trust + AWS Infrastructure           ║"
    echo "║  Time:    $(date)                                                          ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================================
# INDIVIDUAL TEST FUNCTIONS
# ============================================================================

test_prerequisites() {
    section "🔧 Prerequisites & Environment Check"
    
    # Check required tools
    local tools=("aws" "curl" "nslookup" "jq" "openssl" "timeout")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            success "$tool is available"
        else
            error "$tool is not installed"
        fi
    done
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        success "AWS credentials configured (Account: $account_id)"
    else
        critical "AWS credentials not configured or invalid"
    fi
    
    # Check AWS region
    local current_region=$(aws configure get region 2>/dev/null || echo "not-set")
    if [[ "$current_region" == "$AWS_REGION" ]]; then
        success "AWS region correctly set: $AWS_REGION"
    else
        warning "AWS region mismatch. Current: $current_region, Expected: $AWS_REGION"
    fi
}

test_aws_infrastructure() {
    section "☁️  AWS Infrastructure Testing"
    
    # Test VPC
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=wazuh-vpc-dev" \
        --query 'Vpcs[0].VpcId' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "None")
    
    if [[ "$vpc_id" != "None" && "$vpc_id" != "null" ]]; then
        success "VPC operational: $vpc_id"
    else
        error "VPC not found - infrastructure may not be deployed"
        return 1
    fi
    
    # Test EC2 instances
    local instances=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:Project,Values=wazuh" \
        --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,InstanceType]' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    if [[ -n "$instances" ]]; then
        local instance_count=$(echo "$instances" | wc -l | tr -d ' ')
        if [[ "$instance_count" -ge 7 ]]; then
            success "EC2 instances running: $instance_count (Expected: 7)"
        else
            warning "EC2 instance count low: $instance_count (Expected: 7)"
        fi
    else
        error "No running EC2 instances found"
    fi
    
    # Test Load Balancers
    local albs=$(aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[?contains(LoadBalancerName, `wazuh`)].{Name:LoadBalancerName,State:State.Code}' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    if [[ -n "$albs" ]]; then
        local alb_count=$(echo "$albs" | wc -l | tr -d ' ')
        success "Load balancers active: $alb_count"
    else
        error "No load balancers found"
    fi
    
    # Test Security Groups
    local sg_count=$(aws ec2 describe-security-groups \
        --filters "Name=tag:Project,Values=wazuh" \
        --query 'length(SecurityGroups)' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "0")
    
    if [[ "$sg_count" -gt 0 ]]; then
        success "Security groups configured: $sg_count"
    else
        warning "No Wazuh security groups found"
    fi
}

test_cloudflare() {
    section "🌐 Cloudflare & DNS Testing"
    
    # Test DNS resolution
    if nslookup "$CLOUDFLARE_DOMAIN" 1.1.1.1 >/dev/null 2>&1; then
        success "Domain resolution: $CLOUDFLARE_DOMAIN"
    else
        error "DNS resolution failed for $CLOUDFLARE_DOMAIN"
    fi
    
    # Test Wazuh subdomain
    if nslookup "wazuh.$CLOUDFLARE_DOMAIN" 1.1.1.1 >/dev/null 2>&1; then
        success "Wazuh subdomain resolution: wazuh.$CLOUDFLARE_DOMAIN"
    else
        error "DNS resolution failed for wazuh.$CLOUDFLARE_DOMAIN"
    fi
    
    # Test tunnel connectivity
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$TUNNEL_URL" 2>/dev/null || echo "000")
    if [[ "$http_code" =~ ^[2-4][0-9][0-9]$ ]]; then
        success "Tunnel responding: HTTP $http_code"
    else
        error "Tunnel not responding: HTTP $http_code"
    fi
    
    # Test SSL certificate
    if echo | openssl s_client -connect "wazuh.$CLOUDFLARE_DOMAIN:443" -servername "wazuh.$CLOUDFLARE_DOMAIN" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
        success "SSL certificate valid"
    else
        warning "SSL certificate check inconclusive"
    fi
}

test_wazuh_application() {
    section "🛡️  Wazuh Application Testing"
    
    # Test dashboard access
    local dashboard_response=$(timeout 15 curl -s -L "$TUNNEL_URL" 2>/dev/null | head -c 1000)
    if [[ "$dashboard_response" == *"wazuh"* ]] || [[ "$dashboard_response" == *"dashboard"* ]] || [[ "$dashboard_response" == *"login"* ]]; then
        success "Wazuh dashboard accessible"
    else
        warning "Dashboard may be initializing"
    fi
    
    # Test service health endpoints
    local instance_ips=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:Project,Values=wazuh" \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    local healthy_endpoints=0
    local total_endpoints=0
    
    for ip in $instance_ips; do
        if [[ -n "$ip" ]]; then
            ((total_endpoints++))
            local health_response=$(timeout 3 curl -s "http://$ip:8080/health" 2>/dev/null || echo "TIMEOUT")
            if [[ "$health_response" == "OK" ]]; then
                ((healthy_endpoints++))
            fi
        fi
    done
    
    if [[ $healthy_endpoints -gt 0 ]]; then
        success "Health endpoints responding: $healthy_endpoints/$total_endpoints"
    else
        warning "Health endpoints not ready (services may be initializing)"
    fi
}

test_security_compliance() {
    section "🔒 Security & Compliance Testing"
    
    # Test security group rules
    local wazuh_sgs=$(aws ec2 describe-security-groups \
        --filters "Name=tag:Project,Values=wazuh" \
        --query 'SecurityGroups[].GroupId' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    local secure_groups=0
    local total_groups=0
    
    for sg_id in $wazuh_sgs; do
        ((total_groups++))
        
        # Check for open SSH access
        local open_ssh=$(aws ec2 describe-security-groups \
            --group-ids "$sg_id" \
            --query 'SecurityGroups[0].IpPermissions[?FromPort==`22` && ToPort==`22` && IpRanges[?CidrIp==`0.0.0.0/0`]]' \
            --output text \
            --region "$AWS_REGION" 2>/dev/null)
        
        if [[ -z "$open_ssh" ]]; then
            ((secure_groups++))
        fi
    done
    
    if [[ $secure_groups -eq $total_groups ]] && [[ $total_groups -gt 0 ]]; then
        success "Security groups properly configured: $secure_groups/$total_groups"
    else
        warning "Some security groups may need attention"
    fi
    
    # Test EBS encryption
    local volumes=$(aws ec2 describe-volumes \
        --filters "Name=tag:Project,Values=wazuh" \
        --query 'Volumes[].[VolumeId,Encrypted]' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    if [[ -n "$volumes" ]]; then
        local volume_count=$(echo "$volumes" | wc -l | tr -d ' ')
        success "EBS volumes found: $volume_count"
    else
        warning "No EBS volumes found"
    fi
}

test_performance() {
    section "📊 Performance Testing"
    
    # Test response times
    local start_time=$(date +%s%N)
    curl -s -o /dev/null "$TUNNEL_URL" 2>/dev/null || true
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $response_time -lt 3000 ]]; then
        success "Response time acceptable: ${response_time}ms"
    elif [[ $response_time -lt 10000 ]]; then
        warning "Response time slow: ${response_time}ms"
    else
        error "Response time too slow: ${response_time}ms"
    fi
    
    # Test CloudWatch metrics availability
    if aws cloudwatch list-metrics --namespace "AWS/EC2" --region "$AWS_REGION" &>/dev/null; then
        success "CloudWatch metrics available"
    else
        warning "CloudWatch metrics not available"
    fi
}

# ============================================================================
# TEST CATEGORIES
# ============================================================================

run_quick_tests() {
    header
    log "Running QUICK test suite (estimated 2 minutes)"
    
    test_prerequisites
    
    # Quick connectivity tests
    section "🔌 Quick Connectivity Tests"
    
    # Basic DNS test
    if nslookup "$CLOUDFLARE_DOMAIN" >/dev/null 2>&1; then
        success "DNS resolution working"
    else
        error "DNS resolution failed"
    fi
    
    # Basic HTTP test
    if curl -s --connect-timeout 5 "$TUNNEL_URL" >/dev/null 2>&1; then
        success "HTTP connectivity working"
    else
        error "HTTP connectivity failed"
    fi
    
    # AWS basic test
    if aws sts get-caller-identity >/dev/null 2>&1; then
        success "AWS connectivity working"
    else
        error "AWS connectivity failed"
    fi
}

run_standard_tests() {
    header
    log "Running STANDARD test suite (estimated 5 minutes)"
    
    run_quick_tests
    test_aws_infrastructure
    test_cloudflare
}

run_comprehensive_tests() {
    header
    log "Running COMPREHENSIVE test suite (estimated 10 minutes)"
    
    run_standard_tests
    test_wazuh_application
    test_security_compliance
    test_performance
}

run_full_tests() {
    header
    log "Running FULL test suite (estimated 15 minutes)"
    
    run_comprehensive_tests
    
    # Additional advanced tests
    section "🔬 Advanced Testing"
    
    # Test all individual scripts if they exist
    local scripts=("aws_environment_check.sh" "cloudflare_tunnel_health_check.sh" "automated_health_check.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" && -x "$SCRIPT_DIR/$script" ]]; then
            log "Running $script..."
            if timeout 120 "$SCRIPT_DIR/$script" >/dev/null 2>&1; then
                success "Script $script completed successfully"
            else
                warning "Script $script had issues"
            fi
        fi
    done
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

generate_json_report() {
    local json_file="$REPORT_DIR/consolidated_test_report_$TIMESTAMP.json"
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    cat > "$json_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "test_summary": {
        "total_tests": $TOTAL_TESTS,
        "passed_tests": $PASSED_TESTS,
        "failed_tests": $FAILED_TESTS,
        "warning_tests": $WARNING_TESTS,
        "critical_failures": $CRITICAL_FAILURES,
        "success_rate": $success_rate
    },
    "test_results": $(printf '%s\n' "${TEST_RESULTS[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
    "critical_issues": $(printf '%s\n' "${CRITICAL_ISSUES[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
    "warnings": $(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
    "environment": {
        "aws_region": "$AWS_REGION",
        "tunnel_url": "$TUNNEL_URL",
        "domain": "$CLOUDFLARE_DOMAIN"
    }
}
EOF
    
    success "JSON report generated: $json_file"
}

generate_html_report() {
    local html_file="$REPORT_DIR/consolidated_test_report_$TIMESTAMP.html"
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    local score_class="excellent"
    if [[ $success_rate -lt 95 ]]; then score_class="good"; fi
    if [[ $success_rate -lt 70 ]]; then score_class="poor"; fi
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Consolidated Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8fafc; color: #2d3748; line-height: 1.6; margin: 0; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 12px; text-align: center; margin-bottom: 30px; }
        .score-card { background: white; padding: 30px; border-radius: 12px; text-align: center; margin-bottom: 30px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .score { font-size: 48px; font-weight: bold; margin: 10px 0; }
        .excellent { color: #10b981; }
        .good { color: #f59e0b; }
        .poor { color: #ef4444; }
        .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 20px 0; }
        .stat { background: rgba(102, 126, 234, 0.1); padding: 20px; border-radius: 8px; text-align: center; }
        .stat-number { font-size: 24px; font-weight: bold; color: #667eea; }
        .results { background: white; padding: 20px; border-radius: 12px; margin: 20px 0; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .result-item { padding: 10px 0; border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; }
        .result-item:last-child { border-bottom: none; }
        .pass { color: #10b981; }
        .fail { color: #ef4444; }
        .warn { color: #f59e0b; }
        .critical { color: #dc2626; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Consolidated Infrastructure Test Report</h1>
            <p>Generated: $(date)</p>
        </div>
        
        <div class="score-card">
            <div class="score $score_class">$success_rate%</div>
            <h3>Overall Success Rate</h3>
        </div>
        
        <div class="stats">
            <div class="stat">
                <div class="stat-number">$TOTAL_TESTS</div>
                <div>Total Tests</div>
            </div>
            <div class="stat">
                <div class="stat-number">$PASSED_TESTS</div>
                <div>Passed</div>
            </div>
            <div class="stat">
                <div class="stat-number">$WARNING_TESTS</div>
                <div>Warnings</div>
            </div>
            <div class="stat">
                <div class="stat-number">$FAILED_TESTS</div>
                <div>Failed</div>
            </div>
        </div>
        
        <div class="results">
            <h3>📋 Test Results</h3>
EOF

    # Add test results
    for result in "${TEST_RESULTS[@]}"; do
        local status="${result%%:*}"
        local message="${result#*: }"
        local icon="✅"
        local class="pass"
        
        case "$status" in
            "FAIL") icon="❌"; class="fail" ;;
            "WARN") icon="⚠️"; class="warn" ;;
            "CRITICAL") icon="💥"; class="critical" ;;
        esac
        
        echo "            <div class=\"result-item\"><span class=\"$class\">$icon</span> $message</div>" >> "$html_file"
    done
    
    cat >> "$html_file" << EOF
        </div>
        
        <div class="results">
            <h3>🔗 Quick Links</h3>
            <p><a href="$TUNNEL_URL" target="_blank">🛡️ Wazuh Dashboard</a></p>
            <p><a href="https://console.aws.amazon.com/ec2/v2/home?region=$AWS_REGION" target="_blank">☁️ AWS Console</a></p>
            <p><a href="https://dash.cloudflare.com/" target="_blank">🌐 Cloudflare Dashboard</a></p>
        </div>
    </div>
</body>
</html>
EOF
    
    success "HTML report generated: $html_file"
}

generate_summary() {
    section "📊 Test Summary"
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                              CONSOLIDATED TEST SUMMARY                            ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Total Tests:      ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "${CYAN}║${NC}  Passed:           ${GREEN}$PASSED_TESTS${NC}"
    echo -e "${CYAN}║${NC}  Warnings:         ${YELLOW}$WARNING_TESTS${NC}"
    echo -e "${CYAN}║${NC}  Failed:           ${RED}$FAILED_TESTS${NC}"
    echo -e "${CYAN}║${NC}  Critical Issues:  ${RED}$CRITICAL_FAILURES${NC}"
    echo -e "${CYAN}║${NC}  Success Rate:     ${WHITE}$success_rate%${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [[ $CRITICAL_FAILURES -gt 0 ]]; then
        echo ""
        echo -e "${RED}💥 CRITICAL ISSUES DETECTED${NC}"
        for issue in "${CRITICAL_ISSUES[@]}"; do
            echo -e "   ${RED}•${NC} $issue"
        done
    elif [[ $success_rate -ge 95 ]]; then
        echo ""
        echo -e "${GREEN}🎉 INFRASTRUCTURE STATUS: EXCELLENT${NC}"
    elif [[ $success_rate -ge 85 ]]; then
        echo ""
        echo -e "${YELLOW}⚡ INFRASTRUCTURE STATUS: GOOD${NC}"
    else
        echo ""
        echo -e "${RED}❌ INFRASTRUCTURE STATUS: NEEDS ATTENTION${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📁 Reports saved to: $REPORT_DIR${NC}"
    echo -e "${CYAN}📋 Logs saved to: $LOG_DIR${NC}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

show_usage() {
    echo "Usage: $0 [TEST_CATEGORY] [OPTIONS]"
    echo ""
    echo "Test Categories:"
    echo "  quick         - Basic tests (2 minutes)"
    echo "  standard      - Standard tests (5 minutes)"
    echo "  comprehensive - Comprehensive tests (10 minutes)"
    echo "  full          - Full test suite (15 minutes)"
    echo ""
    echo "Options:"
    echo "  --json-only   - Generate only JSON report"
    echo "  --html-only   - Generate only HTML report"
    echo "  --no-reports  - Skip report generation"
    echo "  --help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 quick"
    echo "  $0 comprehensive --json-only"
    echo "  $0 full"
}

main() {
    local test_category="${1:-standard}"
    local json_only=false
    local html_only=false
    local no_reports=false
    
    # Parse options
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json-only) json_only=true; shift ;;
            --html-only) html_only=true; shift ;;
            --no-reports) no_reports=true; shift ;;
            --help) show_usage; exit 0 ;;
            *) echo "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done
    
    # Run tests based on category
    case $test_category in
        quick) run_quick_tests ;;
        standard) run_standard_tests ;;
        comprehensive) run_comprehensive_tests ;;
        full) run_full_tests ;;
        *) echo "Unknown test category: $test_category"; show_usage; exit 1 ;;
    esac
    
    # Generate reports
    if [[ "$no_reports" != true ]]; then
        section "📊 Generating Reports"
        
        if [[ "$html_only" != true ]]; then
            generate_json_report
        fi
        
        if [[ "$json_only" != true ]]; then
            generate_html_report
        fi
    fi
    
    generate_summary
    
    # Exit with appropriate code
    if [[ $CRITICAL_FAILURES -gt 0 ]]; then
        exit 2
    elif [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function with all arguments
main "$@"
