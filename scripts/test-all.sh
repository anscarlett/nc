#!/usr/bin/env bash
# Automated testing framework for NixOS configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$REPO_ROOT/test-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test functions
test_flake_syntax() {
    log "Testing flake syntax..."
    if nix flake check --no-build "$REPO_ROOT" 2>"$TEST_RESULTS_DIR/flake-check.log"; then
        success "Flake syntax is valid"
        return 0
    else
        error "Flake syntax errors found"
        cat "$TEST_RESULTS_DIR/flake-check.log"
        return 1
    fi
}

test_configuration_builds() {
    log "Testing configuration builds..."
    local failed=0
    
    # Get all nixOS configurations
    local configs
    configs=$(nix eval --json "$REPO_ROOT#nixosConfigurations" --apply builtins.attrNames 2>/dev/null | jq -r '.[]')
    
    for config in $configs; do
        log "Building configuration: $config"
        if timeout 300 nix build "$REPO_ROOT#nixosConfigurations.$config.config.system.build.toplevel" --no-link --show-trace 2>"$TEST_RESULTS_DIR/build-$config.log"; then
            success "Configuration $config builds successfully"
        else
            error "Configuration $config failed to build"
            ((failed++))
        fi
    done
    
    return $failed
}

test_home_configurations() {
    log "Testing home-manager configurations..."
    local failed=0
    
    # Get all home configurations
    local configs
    if configs=$(nix eval --json "$REPO_ROOT#homeConfigurations" --apply builtins.attrNames 2>/dev/null | jq -r '.[]'); then
        for config in $configs; do
            log "Building home configuration: $config"
            if timeout 180 nix build "$REPO_ROOT#homeConfigurations.$config.activationPackage" --no-link 2>"$TEST_RESULTS_DIR/home-$config.log"; then
                success "Home configuration $config builds successfully"
            else
                error "Home configuration $config failed to build"
                ((failed++))
            fi
        done
    else
        warning "No home configurations found or evaluation failed"
    fi
    
    return $failed
}

test_vm_functionality() {
    log "Testing VM functionality..."
    local failed=0
    
    # Test VM configuration builds
    local vm_configs=("vm-test")
    
    for config in "${vm_configs[@]}"; do
        log "Building VM for configuration: $config"
        if timeout 600 nix build "$REPO_ROOT#nixosConfigurations.$config.config.system.build.vm" --no-link 2>"$TEST_RESULTS_DIR/vm-$config.log"; then
            success "VM $config builds successfully"
        else
            error "VM $config failed to build"
            ((failed++))
        fi
    done
    
    return $failed
}

test_secrets_structure() {
    log "Testing secrets structure..."
    local failed=0
    
    # Check if secrets.nix exists and is valid
    if [[ -f "$REPO_ROOT/secrets.nix" ]]; then
        if nix-instantiate --eval "$REPO_ROOT/secrets.nix" >/dev/null 2>"$TEST_RESULTS_DIR/secrets-check.log"; then
            success "Secrets structure is valid"
        else
            error "Secrets structure has issues"
            ((failed++))
        fi
    else
        warning "No secrets.nix found (this may be intentional)"
    fi
    
    return $failed
}

test_documentation() {
    log "Testing documentation consistency..."
    local failed=0
    
    # Check for broken internal links (basic check)
    if command -v markdownlint &> /dev/null; then
        if markdownlint "$REPO_ROOT/docs/"*.md "$REPO_ROOT/README.md" 2>"$TEST_RESULTS_DIR/markdown-lint.log"; then
            success "Markdown documentation is well-formatted"
        else
            warning "Markdown formatting issues found"
        fi
    else
        warning "markdownlint not available, skipping documentation tests"
    fi
    
    # Check for outdated references
    if grep -r "homes/obsolete/" "$REPO_ROOT/docs/" >/dev/null 2>&1; then
        error "Found outdated 'obsolete' references in documentation"
        ((failed++))
    else
        success "No outdated references found in documentation"
    fi
    
    return $failed
}

# Performance benchmarking
benchmark_build_times() {
    log "Benchmarking build times..."
    
    local start_time
    start_time=$(date +%s)
    
    # Build a simple configuration for benchmarking
    if nix build "$REPO_ROOT#nixosConfigurations.vm-test.config.system.build.toplevel" --no-link --rebuild >/dev/null 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo "Build time: ${duration}s" > "$TEST_RESULTS_DIR/benchmark.log"
        success "Benchmark completed: ${duration}s"
    else
        error "Benchmark failed"
    fi
}

# Health checks
health_check() {
    log "Running health checks..."
    local failed=0
    
    # Check disk space
    local available_space
    available_space=$(df "$REPO_ROOT" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then # Less than 1GB
        warning "Low disk space: $(( available_space / 1024 ))MB available"
    else
        success "Disk space: $(( available_space / 1048576 ))GB available"
    fi
    
    # Check Nix store health
    if nix store verify --all >/dev/null 2>&1; then
        success "Nix store is healthy"
    else
        warning "Nix store verification issues found"
    fi
    
    return $failed
}

# Main test runner
run_tests() {
    log "Starting automated test suite..."
    local total_failed=0
    
    # Create test report
    local report_file="$TEST_RESULTS_DIR/test-report-$(date +%Y%m%d-%H%M%S).txt"
    exec > >(tee "$report_file") 2>&1
    
    echo "========================================="
    echo "NixOS Configuration Test Report"
    echo "Date: $(date)"
    echo "========================================="
    echo
    
    # Run all tests
    test_flake_syntax || ((total_failed++))
    echo
    
    test_configuration_builds || ((total_failed++))
    echo
    
    test_home_configurations || ((total_failed++))
    echo
    
    test_vm_functionality || ((total_failed++))
    echo
    
    test_secrets_structure || ((total_failed++))
    echo
    
    test_documentation || ((total_failed++))
    echo
    
    health_check || ((total_failed++))
    echo
    
    # Benchmark (doesn't affect pass/fail)
    benchmark_build_times
    echo
    
    # Summary
    echo "========================================="
    if [[ $total_failed -eq 0 ]]; then
        success "All tests passed! 🎉"
        echo "Test report: $report_file"
        exit 0
    else
        error "$total_failed test(s) failed"
        echo "Test report: $report_file"
        exit 1
    fi
}

# CLI interface
case "${1:-run}" in
    "syntax")
        test_flake_syntax
        ;;
    "build")
        test_configuration_builds
        ;;
    "vm")
        test_vm_functionality
        ;;
    "health")
        health_check
        ;;
    "benchmark")
        benchmark_build_times
        ;;
    "run"|*)
        run_tests
        ;;
esac
