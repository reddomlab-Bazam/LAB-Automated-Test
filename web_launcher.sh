#!/bin/bash

# ============================================================================
# WEB INTERFACE LAUNCHER FOR CONSOLIDATED TESTS
# ============================================================================
# This script provides a simple interface that can be called from the HTML
# dashboard or any web interface to execute infrastructure tests.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_SCRIPT="$SCRIPT_DIR/master_consolidated_test.sh"

# Function to return JSON response
json_response() {
    local status="$1"
    local message="$2"
    local data="$3"
    
    echo "Content-Type: application/json"
    echo ""
    echo "{\"status\": \"$status\", \"message\": \"$message\", \"data\": $data}"
}

# Function to execute test and return results
execute_test() {
    local test_type="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local log_file="$SCRIPT_DIR/test-logs/web_test_$timestamp.log"
    
    # Ensure log directory exists
    mkdir -p "$SCRIPT_DIR/test-logs"
    
    # Execute the test
    if timeout 1800 "$MASTER_SCRIPT" "$test_type" --json-only > "$log_file" 2>&1; then
        local exit_code=$?
        local report_file=$(ls -t "$SCRIPT_DIR/test-reports"/consolidated_test_report_*.json 2>/dev/null | head -1)
        
        if [[ -f "$report_file" ]]; then
            local report_data=$(cat "$report_file")
            json_response "success" "Test completed successfully" "$report_data"
        else
            json_response "success" "Test completed but report not found" "{}"
        fi
    else
        local exit_code=$?
        json_response "error" "Test failed with exit code $exit_code" "{\"exit_code\": $exit_code}"
    fi
}

# Function to get system status
get_status() {
    local status_data="{
        \"timestamp\": \"$(date -Iseconds)\",
        \"aws_region\": \"${AWS_REGION:-eu-west-2}\",
        \"tunnel_url\": \"https://wazuh.reddomelab.space\",
        \"scripts_available\": $(ls -1 "$SCRIPT_DIR"/*.sh 2>/dev/null | wc -l),
        \"recent_reports\": $(ls -1 "$SCRIPT_DIR/test-reports"/*.json 2>/dev/null | wc -l)
    }"
    
    json_response "success" "Status retrieved" "$status_data"
}

# Function to list available tests
list_tests() {
    local tests_data="{
        \"quick\": {\"name\": \"Quick Tests\", \"duration\": \"2 minutes\", \"description\": \"Basic connectivity and configuration tests\"},
        \"standard\": {\"name\": \"Standard Tests\", \"duration\": \"5 minutes\", \"description\": \"Standard infrastructure tests\"},
        \"comprehensive\": {\"name\": \"Comprehensive Tests\", \"duration\": \"10 minutes\", \"description\": \"Full infrastructure validation\"},
        \"full\": {\"name\": \"Full Test Suite\", \"duration\": \"15 minutes\", \"description\": \"Complete test suite including master tests\"}
    }"
    
    json_response "success" "Tests listed" "$tests_data"
}

# Function to get latest report
get_latest_report() {
    local latest_json=$(ls -t "$SCRIPT_DIR/test-reports"/consolidated_test_report_*.json 2>/dev/null | head -1)
    local latest_html=$(ls -t "$SCRIPT_DIR/test-reports"/consolidated_test_report_*.html 2>/dev/null | head -1)
    
    if [[ -f "$latest_json" ]]; then
        local report_data=$(cat "$latest_json")
        local report_info="{
            \"json_report\": \"$(basename "$latest_json")\",
            \"html_report\": \"$(basename "$latest_html")\",
            \"report_data\": $report_data
        }"
        json_response "success" "Latest report retrieved" "$report_info"
    else
        json_response "error" "No reports found" "{}"
    fi
}

# Main execution
main() {
    local action="${1:-status}"
    local test_type="${2:-standard}"
    
    case "$action" in
        "execute")
            execute_test "$test_type"
            ;;
        "status")
            get_status
            ;;
        "list")
            list_tests
            ;;
        "report")
            get_latest_report
            ;;
        *)
            json_response "error" "Unknown action: $action" "{}"
            ;;
    esac
}

# Handle CGI environment if present
if [[ -n "$QUERY_STRING" ]]; then
    # Parse query string for web interface
    eval $(echo "$QUERY_STRING" | tr '&' '\n' | sed 's/\([^=]*\)=\(.*\)/\1="\2"/')
    main "${action:-status}" "${test_type:-standard}"
else
    # Command line usage
    main "$@"
fi
