#!/usr/bin/env bash
#
# Test suite for qb script
#
# This test suite covers:
# - Command line argument parsing
# - Project root detection
# - Maven configuration
# - Git integration
# - Docker retagging functionality
# - Error handling

set -euo pipefail

# Test configuration
TEST_DIR="/tmp/qb_test_$$"
SCRIPT_PATH="/home/aaron/bin/qb"
TEST_RESULTS=()
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test helper functions
log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    if [[ "$status" == "PASS" ]]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $test_name: $message"
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo -e "${RED}✗${NC} $test_name: $message"
    fi
    TEST_RESULTS+=("$status|$test_name|$message")
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment in $TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Create a mock Maven project structure
    mkdir -p "test-project/subdir"
    cat > "test-project/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.test</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
</project>
EOF
    
    # Create a mock Maven wrapper
    cat > "test-project/mvnw" << 'EOF'
#!/bin/bash
echo "Mock Maven wrapper executed with args: $*"
# Simulate successful build
exit 0
EOF
    chmod +x "test-project/mvnw"
    
    # Create a mock git repository
    cd "test-project"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test content" > test.txt
    git add test.txt
    git commit --quiet -m "Initial commit"
    cd ..
    
    # Create a mock Docker environment
    # We'll mock docker commands in the test functions
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment"
    cd /
    rm -rf "$TEST_DIR"
}

# Test helper functions (simplified for basic functionality testing)

# Test functions
test_help_option() {
    log_info "Testing --help option"
    
    local output
    output=$(cd "$TEST_DIR/test-project" && "$SCRIPT_PATH" --help 2>&1 || true)
    
    if echo "$output" | grep -q "Usage:" && echo "$output" | grep -q "Quick Build with Docker"; then
        log_test "help_option" "PASS" "Help text displayed correctly"
    else
        log_test "help_option" "FAIL" "Help text not displayed correctly"
    fi
}

test_project_root_detection() {
    log_info "Testing project root detection"
    
    # Test from project root
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Project root: $TEST_DIR/test-project"; then
        log_test "project_root_from_root" "PASS" "Project root detected correctly from root"
    else
        log_test "project_root_from_root" "FAIL" "Project root not detected correctly from root"
    fi
    
    # Test from subdirectory
    output=$(cd "$TEST_DIR/test-project/subdir" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Project root: $TEST_DIR/test-project"; then
        log_test "project_root_from_subdir" "PASS" "Project root detected correctly from subdirectory"
    else
        log_test "project_root_from_subdir" "FAIL" "Project root not detected correctly from subdirectory"
    fi
}

test_no_pom_error() {
    log_info "Testing error when no pom.xml found"
    
    local output
    output=$(cd "$TEST_DIR" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Error: No pom.xml found"; then
        log_test "no_pom_error" "PASS" "Correct error message when no pom.xml found"
    else
        log_test "no_pom_error" "FAIL" "Missing or incorrect error message when no pom.xml found"
    fi
}

test_argument_parsing() {
    log_info "Testing command line argument parsing"
    
    # Test --dirty option
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --dirty --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Goals: install"; then
        log_test "dirty_option" "PASS" "--dirty option sets goals to install only"
    else
        log_test "dirty_option" "FAIL" "--dirty option not working correctly"
    fi
    
    # Test --test option
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --test --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Executing:.*mvnw.*-Dmaven.repo.local" && ! echo "$output" | grep -q -- "-DskipTests"; then
        log_test "test_option" "PASS" "--test option disables skipTests"
    else
        log_test "test_option" "FAIL" "--test option not working correctly"
    fi
    
    # Test --default-repo option
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --default-repo --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Using default Maven repository: $HOME/.m2/repository"; then
        log_test "default_repo_option" "PASS" "--default-repo option uses default repository"
    else
        log_test "default_repo_option" "FAIL" "--default-repo option not working correctly"
    fi
    
    # Test --single-thread option
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --single-thread --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Multi-threading: Disabled"; then
        log_test "single_thread_option" "PASS" "--single-thread option disables multithreading"
    else
        log_test "single_thread_option" "FAIL" "--single-thread option not working correctly"
    fi
    
    # Test --no-retag option
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Retagging disabled - build complete"; then
        log_test "no_retag_option" "PASS" "--no-retag option disables retagging"
    else
        log_test "no_retag_option" "FAIL" "--no-retag option not working correctly"
    fi
}

test_maven_configuration() {
    log_info "Testing Maven configuration"
    
    # Test default configuration
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Multi-threading: Enabled (-T6)" && echo "$output" | grep -q -- "-DskipTests"; then
        log_test "maven_default_config" "PASS" "Default Maven configuration is correct"
    else
        log_test "maven_default_config" "FAIL" "Default Maven configuration is incorrect"
    fi
    
    # Test project-specific repository
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Using project-specific repository: $TEST_DIR/test-project/.m2/repository"; then
        log_test "project_specific_repo" "PASS" "Project-specific repository is used by default"
    else
        log_test "project_specific_repo" "FAIL" "Project-specific repository not used correctly"
    fi
}

test_git_integration() {
    log_info "Testing Git integration"
    
    # Test with git repository
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Project root: $TEST_DIR/test-project"; then
        log_test "git_integration" "PASS" "Script works in git repository"
    else
        log_test "git_integration" "FAIL" "Script failed in git repository"
    fi
    
    # Test without git repository
    cd "$TEST_DIR"
    rm -rf test-project/.git
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    if echo "$output" | grep -q "Warning: Not in a git repository, skipping retagging"; then
        log_test "no_git_warning" "PASS" "Correct warning when not in git repository"
    else
        log_test "no_git_warning" "FAIL" "Missing warning when not in git repository"
    fi
}

test_docker_retagging() {
    log_info "Testing Docker retagging functionality"
    
    # Recreate git repo for this test
    cd "$TEST_DIR/test-project"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test content" > test.txt
    git add test.txt
    git commit --quiet -m "Initial commit"
    
    # Run the script with --no-retag to test the basic functionality
    local output
    output=$(timeout 10 "$SCRIPT_PATH" --no-retag 2>&1 || true)
    
    # Check if the script runs successfully
    if echo "$output" | grep -q "Retagging disabled - build complete"; then
        log_test "docker_retag_basic" "PASS" "Script runs successfully with retagging disabled"
    else
        log_test "docker_retag_basic" "FAIL" "Script failed to run with retagging disabled"
    fi
    
    # Test that retagging is properly disabled
    if echo "$output" | grep -q "Retagging disabled - build complete"; then
        log_test "docker_retag_disabled" "PASS" "Retagging is properly disabled with --no-retag"
    else
        log_test "docker_retag_disabled" "FAIL" "Retagging was not properly disabled"
    fi
    
    # Test that the script attempts retagging when enabled (even if it fails due to no Docker)
    output=$(timeout 10 "$SCRIPT_PATH" 2>&1 || true)
    
    if echo "$output" | grep -q "Looking for recently built images from registry.octo-cx-prod.runshiftup.com/octo-cx"; then
        log_test "docker_retag_attempt" "PASS" "Script attempts to retag images when enabled"
    else
        log_test "docker_retag_attempt" "FAIL" "Script does not attempt to retag images"
    fi
}

test_custom_maven_goals() {
    log_info "Testing custom Maven goals"
    
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag compile 2>&1 || true)
    
    if echo "$output" | grep -q "Goals: compile"; then
        log_test "custom_maven_goals" "PASS" "Custom Maven goals are accepted"
    else
        log_test "custom_maven_goals" "FAIL" "Custom Maven goals not accepted"
    fi
}

test_custom_maven_args() {
    log_info "Testing custom Maven arguments"
    
    local output
    output=$(cd "$TEST_DIR/test-project" && timeout 5 "$SCRIPT_PATH" --no-retag -Dcustom.property=value 2>&1 || true)
    
    if echo "$output" | grep -q "Executing:.*-Dcustom.property=value"; then
        log_test "custom_maven_args" "PASS" "Custom Maven arguments are passed through"
    else
        log_test "custom_maven_args" "FAIL" "Custom Maven arguments not passed through"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting qb script test suite${NC}"
    echo "=================================="
    
    # Check if script exists
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        echo -e "${RED}Error: Script not found at $SCRIPT_PATH${NC}"
        exit 1
    fi
    
    # Check if script is executable
    if [[ ! -x "$SCRIPT_PATH" ]]; then
        echo -e "${RED}Error: Script is not executable${NC}"
        exit 1
    fi
    
    setup_test_env
    
    # Run all tests
    test_help_option
    test_project_root_detection
    test_no_pom_error
    test_argument_parsing
    test_maven_configuration
    test_git_integration
    test_docker_retagging
    test_custom_maven_goals
    test_custom_maven_args
    
    # Cleanup
    cleanup_test_env
    
    # Print summary
    echo ""
    echo "=================================="
    echo -e "${BLUE}Test Summary${NC}"
    echo "Total tests: $TEST_COUNT"
    echo -e "Passed: ${GREEN}$PASSED_COUNT${NC}"
    echo -e "Failed: ${RED}$FAILED_COUNT${NC}"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        echo ""
        echo "Failed tests:"
        for result in "${TEST_RESULTS[@]}"; do
            IFS='|' read -r status test_name message <<< "$result"
            if [[ "$status" == "FAIL" ]]; then
                echo -e "  ${RED}✗${NC} $test_name: $message"
            fi
        done
        exit 1
    fi
}

# Run main function
main "$@"
