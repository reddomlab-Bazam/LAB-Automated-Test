#!/bin/bash

# ============================================================================
# CENTRALIZED TEST RUNNER FOR INFAMOUSLAB INFRASTRUCTURE
# ============================================================================
# This script runs all available tests in the correct order and provides
# a unified interface for testing the entire infrastructure stack.
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
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="$SCRIPT_DIR/test-logs"
REPORT_DIR="$SCRIPT_DIR/test-reports"

# Create directories
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Available test scripts - Consolidated to essential scripts only
declare -A TEST_SCRIPTS=(
    ["master-consolidated"]="master_consolidated_test.sh"
    ["web-launcher"]="web_launcher.sh"
)

# Test categories - Updated to use consolidated script
declare -A TEST_CATEGORIES=(
    ["quick"]="master-consolidated"
    ["standard"]="master-consolidated"
    ["comprehensive"]="master-consolidated"
    ["full"]="master-consolidated"
)

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
}

section() {
    echo "" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
    echo -e "${PURPLE}  $1${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/test_runner_$TIMESTAMP.log"
}

header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           🚀 INFAMOUSLAB CENTRALIZED TEST RUNNER                               ║"
    echo "║                                                                                                ║"
    echo "║  Unified testing interface for all infrastructure components                                   ║"
    echo "║  Time:    $(date)                                                          ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_CATEGORY]"
    echo ""
    echo "Test Categories (All use consolidated master script):"
    echo "  quick         - Basic connectivity and configuration tests (~2 minutes)"
    echo "  standard      - Standard infrastructure tests (~5 minutes)"
    echo "  comprehensive - Full infrastructure validation (~10 minutes)"
    echo "  full          - Complete test suite including master tests (~15 minutes)"
    echo ""
    echo "Individual Scripts:"
    for test_name in "${!TEST_SCRIPTS[@]}"; do
        echo "  $test_name -> ${TEST_SCRIPTS[$test_name]}"
    done
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -l, --list    List all available tests"
    echo "  -v, --verbose Enable verbose logging"
    echo "  -q, --quiet   Suppress output except errors"
    echo "  --dry-run     Show what would be executed without running"
    echo ""
    echo "Examples:"
    echo "  $0 quick                    # Run quick tests via consolidated script"
    echo "  $0 comprehensive           # Run comprehensive tests"
    echo "  $0 master-consolidated     # Run consolidated script directly"
    echo "  $0 --dry-run full          # Preview what full test would do"
    echo ""
    echo "Note: All test categories now use the master_consolidated_test.sh script"
    echo "      which includes all previous individual test functionality."
}

list_tests() {
    section "📋 Available Test Scripts"
    
    echo "Test Categories:"
    for category in "${!TEST_CATEGORIES[@]}"; do
        echo -e "  ${CYAN}$category${NC}: ${TEST_CATEGORIES[$category]}"
    done
    
    echo ""
    echo "Individual Test Scripts:"
    for test_name in "${!TEST_SCRIPTS[@]}"; do
        local script_file="${TEST_SCRIPTS[$test_name]}"
        if [[ -f "$SCRIPT_DIR/$script_file" ]]; then
            echo -e "  ${GREEN}✅${NC} $test_name -> $script_file"
        else
            echo -e "  ${RED}❌${NC} $test_name -> $script_file (missing)"
        fi
    done
}

run_test() {
    local test_name="$1"
    local script_file="${TEST_SCRIPTS[$test_name]}"
    
    if [[ -z "$script_file" ]]; then
        error "Unknown test: $test_name"
        return 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/$script_file" ]]; then
        error "Test script not found: $script_file"
        return 1
    fi
    
    if [[ ! -x "$SCRIPT_DIR/$script_file" ]]; then
        warning "Making script executable: $script_file"
        chmod +x "$SCRIPT_DIR/$script_file"
    fi
    
    log "Running test: $test_name ($script_file)"
    
    local test_log="$LOG_DIR/${test_name}_$TIMESTAMP.log"
    local exit_code=0
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${BLUE}Would execute:${NC} $SCRIPT_DIR/$script_file"
        return 0
    fi
    
    # Run the test with timeout
    if timeout 600 bash "$SCRIPT_DIR/$script_file" > "$test_log" 2>&1; then
        success "Test completed: $test_name"
        if [[ "$VERBOSE" == "true" ]]; then
            tail -10 "$test_log"
        fi
    else
        exit_code=$?
        error "Test failed: $test_name (exit code: $exit_code)"
        if [[ "$QUIET" != "true" ]]; then
            echo "Last 10 lines of output:"
            tail -10 "$test_log"
        fi
        return $exit_code
    fi
}

run_test_category() {
    local category="$1"
    
    section "🧪 Running $category Tests Using Consolidated Script"
    
    # All test categories now use the master consolidated script with different parameters
    case "$category" in
        "quick"|"standard"|"comprehensive"|"full")
            if ! run_consolidated_test "$category"; then
                error "Consolidated test failed for category: $category"
                return 1
            fi
            ;;
        *)
            error "Unknown test category: $category"
            return 1
            ;;
    esac
    
    success "Test category '$category' completed successfully"
    return 0
}

run_consolidated_test() {
    local test_type="$1"
    local script_file="master_consolidated_test.sh"
    
    if [[ ! -f "$SCRIPT_DIR/$script_file" ]]; then
        error "Consolidated test script not found: $script_file"
        return 1
    fi
    
    if [[ ! -x "$SCRIPT_DIR/$script_file" ]]; then
        warning "Making script executable: $script_file"
        chmod +x "$SCRIPT_DIR/$script_file"
    fi
    
    log "Running consolidated test: $test_type"
    
    local test_log="$LOG_DIR/${test_type}_consolidated_$TIMESTAMP.log"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${BLUE}Would execute:${NC} $SCRIPT_DIR/$script_file $test_type"
        return 0
    fi
    
    # Run the consolidated test with timeout
    if timeout 1800 bash "$SCRIPT_DIR/$script_file" "$test_type" > "$test_log" 2>&1; then
        success "Consolidated test completed: $test_type"
        if [[ "$VERBOSE" == "true" ]]; then
            tail -20 "$test_log"
        fi
        return 0
    else
        local exit_code=$?
        error "Consolidated test failed: $test_type (exit code: $exit_code)"
        if [[ "$QUIET" != "true" ]]; then
            echo "Last 20 lines of output:"
            tail -20 "$test_log"
        fi
        return $exit_code
    fi
}

validate_environment() {
    section "🔍 Environment Validation"
    
    # Check if we're in the right directory
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        error "Cannot find LAB-Automated-Test directory"
        return 1
    fi
    
    # Check for required scripts
    local missing_scripts=0
    for test_name in "${!TEST_SCRIPTS[@]}"; do
        local script_file="${TEST_SCRIPTS[$test_name]}"
        if [[ ! -f "$SCRIPT_DIR/$script_file" ]]; then
            warning "Missing test script: $script_file"
            ((missing_scripts++))
        fi
    done
    
    if [[ $missing_scripts -gt 0 ]]; then
        warning "$missing_scripts test scripts are missing"
    else
        success "All test scripts are available"
    fi
    
    # Check for required tools
    local tools=("aws" "curl" "nslookup" "timeout")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log "Tool available: $tool"
        else
            warning "Tool missing: $tool"
        fi
    done
}

generate_summary_report() {
    section "📊 Generating Summary Report"
    
    local summary_file="$REPORT_DIR/test_summary_$TIMESTAMP.md"
    
    cat > "$summary_file" << EOF
# InfamousLab Infrastructure Test Summary

**Generated:** $(date)  
**Test Runner:** Centralized Test Runner  
**Logs Directory:** $LOG_DIR  

## Test Execution Summary

EOF

    # Add test results from logs
    if ls "$LOG_DIR"/*_$TIMESTAMP.log &> /dev/null; then
        echo "## Individual Test Results" >> "$summary_file"
        echo "" >> "$summary_file"
        
        for log_file in "$LOG_DIR"/*_$TIMESTAMP.log; do
            local test_name=$(basename "$log_file" .log | sed "s/_$TIMESTAMP//")
            if [[ "$test_name" != "test_runner" ]]; then
                local status="❌ FAILED"
                if grep -q "✅" "$log_file" 2>/dev/null; then
                    status="✅ PASSED"
                elif grep -q "⚠️" "$log_file" 2>/dev/null; then
                    status="⚠️ WARNING"
                fi
                echo "- **$test_name**: $status" >> "$summary_file"
            fi
        done
    fi
    
    cat >> "$summary_file" << EOF

## Quick Access Links

- 🛡️ [Wazuh Dashboard](https://wazuh.reddomelab.space)
- ☁️ [AWS Console](https://console.aws.amazon.com/ec2/v2/home?region=eu-west-2)
- 🌐 [Cloudflare Dashboard](https://dash.cloudflare.com/)

## Log Files

EOF
    
    # List all log files
    for log_file in "$LOG_DIR"/*_$TIMESTAMP.log; do
        echo "- $(basename "$log_file")" >> "$summary_file"
    done
    
    success "Summary report generated: $summary_file"
}

# Parse command line arguments
VERBOSE=false
QUIET=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            list_tests
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Main execution
main() {
    header
    validate_environment
    
    local target="${1:-standard}"
    
    if [[ "${TEST_CATEGORIES[$target]}" ]]; then
        # Run test category
        run_test_category "$target"
    elif [[ "${TEST_SCRIPTS[$target]}" ]]; then
        # Run individual test
        section "🧪 Running Individual Test"
        run_test "$target"
    else
        error "Unknown test or category: $target"
        echo ""
        show_usage
        exit 1
    fi
    
    generate_summary_report
    
    section "🏁 Test Run Complete"
    echo ""
    echo -e "${CYAN}📁 Logs saved to: $LOG_DIR${NC}"
    echo -e "${CYAN}📊 Reports saved to: $REPORT_DIR${NC}"
    echo ""
}

# Run main function
main "$@"
