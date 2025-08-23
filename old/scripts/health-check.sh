#!/usr/bin/env bash
# Health check system for NixOS configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check auto-discovery system
check_auto_discovery() {
    log "Checking auto-discovery system..."
    local issues=0
    
    # Check if lib functions exist
    if [[ ! -f "$REPO_ROOT/lib/auto-users.nix" ]]; then
        error "Missing lib/auto-users.nix"
        ((issues++))
    else
        success "auto-users.nix found"
    fi
    
    if [[ ! -f "$REPO_ROOT/lib/mk-configs.nix" ]]; then
        error "Missing lib/mk-configs.nix"
        ((issues++))
    else
        success "mk-configs.nix found"
    fi
    
    if [[ ! -f "$REPO_ROOT/lib/get-name-from-path.nix" ]]; then
        error "Missing lib/get-name-from-path.nix"
        ((issues++))
    else
        success "get-name-from-path.nix found"
    fi
    
    # Check folder structure
    if [[ ! -d "$REPO_ROOT/hosts" ]]; then
        error "Missing hosts/ directory"
        ((issues++))
    else
        local host_count
        host_count=$(find "$REPO_ROOT/hosts" -name "host.nix" | wc -l)
        info "Found $host_count host configurations"
    fi
    
    if [[ ! -d "$REPO_ROOT/homes" ]]; then
        error "Missing homes/ directory"
        ((issues++))
    else
        local home_count
        home_count=$(find "$REPO_ROOT/homes" -name "home.nix" | wc -l)
        info "Found $home_count home configurations"
    fi
    
    return $issues
}

# Check secrets management health
check_secrets_health() {
    log "Checking secrets management..."
    local issues=0
    
    # Check if agenix is properly configured
    if grep -q "agenix" "$REPO_ROOT/flake.nix"; then
        success "Agenix input found in flake.nix"
    else
        warning "Agenix not found in flake inputs"
        ((issues++))
    fi
    
    # Check for co-located secrets files (not global secrets)
    local secrets_count
    secrets_count=$(find "$REPO_ROOT/hosts" "$REPO_ROOT/homes" -name "secrets.nix" -o -name "secrets.yaml" 2>/dev/null | wc -l)
    info "Found $secrets_count co-located secrets files"
    
    # Check if there's no global secrets file (which would be incorrect)
    if [[ -f "$REPO_ROOT/secrets.nix" ]]; then
        error "Global secrets.nix file found - secrets should be co-located with hosts/homes"
        ((issues++))
    else
        success "No global secrets file (correct - using co-located secrets)"
    fi
    
    # Check if passwords.nix exists
    if [[ -f "$REPO_ROOT/lib/passwords.nix" ]]; then
        success "Password management helper found"
    else
        warning "Password management helper missing"
    fi
    
    # Check for SSH keys directory
    if [[ -d "$HOME/.ssh" ]]; then
        local key_count
        key_count=$(find "$HOME/.ssh" -name "*.pub" | wc -l)
        info "Found $key_count SSH public keys"
    else
        warning "No SSH directory found"
    fi
    
    return $issues
}

# Check configuration consistency
check_config_consistency() {
    log "Checking configuration consistency..."
    local issues=0
    
    # Check for outdated references
    if grep -r "homes/obsolete/" "$REPO_ROOT" --exclude-dir=".git" --exclude="*.sh" --exclude="*.yml" >/dev/null 2>&1; then
        error "Found outdated 'obsolete' references in configuration files"
        grep -r "homes/obsolete/" "$REPO_ROOT" --exclude-dir=".git" --exclude="*.sh" --exclude="*.yml" | head -5
        ((issues++))
    else
        success "No outdated references found in configuration files"
    fi
    
    # Check for relative imports that should be root-relative
    local relative_imports
    relative_imports=$(grep -r "import.*\.\./\.\." "$REPO_ROOT" --include="*.nix" --exclude-dir=".git" | wc -l)
    if [[ $relative_imports -gt 0 ]]; then
        warning "Found $relative_imports potentially problematic relative imports"
        grep -r "import.*\.\./\.\." "$REPO_ROOT" --include="*.nix" --exclude-dir=".git" | head -3
    else
        success "No problematic relative imports found"
    fi
    
    # Check for hardcoded usernames in host configs
    if grep -r "users.users\." "$REPO_ROOT/hosts" --include="*.nix" | grep -v "passwords\|override" >/dev/null 2>&1; then
        warning "Found potential hardcoded user configurations in hosts"
        grep -r "users.users\." "$REPO_ROOT/hosts" --include="*.nix" | grep -v "passwords\|override" | head -3
    else
        success "No hardcoded user configurations in hosts"
    fi
    
    return $issues
}

# Check build optimization
check_build_optimization() {
    log "Checking build optimization..."
    local issues=0
    
    # Check if build optimization module exists
    if [[ -f "$REPO_ROOT/modules/build-optimization.nix" ]]; then
        success "Build optimization module found"
    else
        warning "Build optimization module missing"
        ((issues++))
    fi
    
    # Check Nix configuration
    if [[ -f "$HOME/.config/nix/nix.conf" ]]; then
        if grep -q "substituters" "$HOME/.config/nix/nix.conf"; then
            success "Binary cache substituters configured"
        else
            info "No custom substituters found in nix.conf"
        fi
        
        if grep -q "builders" "$HOME/.config/nix/nix.conf"; then
            success "Remote builders configured"
        else
            info "No remote builders configured"
        fi
    else
        info "No user nix.conf found"
    fi
    
    # Check system nix configuration
    if [[ -f "/etc/nix/nix.conf" ]]; then
        info "System nix.conf exists"
    else
        info "No system nix.conf found"
    fi
    
    return $issues
}

# Check documentation health
check_documentation() {
    log "Checking documentation..."
    local issues=0
    
    # Check if docs directory exists
    if [[ ! -d "$REPO_ROOT/docs" ]]; then
        error "Missing docs/ directory"
        ((issues++))
    else
        local doc_count
        doc_count=$(find "$REPO_ROOT/docs" -name "*.md" | wc -l)
        info "Found $doc_count documentation files"
        
        # Check for essential docs
        local essential_docs=("customisation.md" "private-config.md" "architecture.md")
        for doc in "${essential_docs[@]}"; do
            if [[ -f "$REPO_ROOT/docs/$doc" ]]; then
                success "$doc found"
            else
                warning "$doc missing"
            fi
        done
    fi
    
    # Check README
    if [[ -f "$REPO_ROOT/README.md" ]]; then
        success "README.md found"
    else
        error "README.md missing"
        ((issues++))
    fi
    
    return $issues
}

# Check system resources
check_system_resources() {
    log "Checking system resources..."
    local issues=0
    
    # Check disk space
    local available_gb
    available_gb=$(df "$REPO_ROOT" | awk 'NR==2 {print int($4/1048576)}')
    if [[ $available_gb -lt 5 ]]; then
        error "Low disk space: ${available_gb}GB available"
        ((issues++))
    elif [[ $available_gb -lt 10 ]]; then
        warning "Limited disk space: ${available_gb}GB available"
    else
        success "Disk space: ${available_gb}GB available"
    fi
    
    # Check memory usage
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $mem_usage -gt 90 ]]; then
        warning "High memory usage: ${mem_usage}%"
    else
        info "Memory usage: ${mem_usage}%"
    fi
    
    # Check Nix store size
    local store_size
    if store_size=$(du -sh /nix/store 2>/dev/null | cut -f1); then
        info "Nix store size: $store_size"
        
        # Check if it's getting large
        local store_gb
        store_gb=$(du -s /nix/store 2>/dev/null | awk '{print int($1/1048576)}')
        if [[ $store_gb -gt 50 ]]; then
            info "Large Nix store (${store_gb}GB) - consider running 'nix-collect-garbage -d'"
        fi
    else
        warning "Cannot determine Nix store size"
    fi
    
    return $issues
}

# Check Git repository health
check_git_health() {
    log "Checking Git repository..."
    local issues=0
    
    if ! git -C "$REPO_ROOT" status >/dev/null 2>&1; then
        error "Not a Git repository or Git not available"
        ((issues++))
        return $issues
    fi
    
    # Check for uncommitted changes
    if git -C "$REPO_ROOT" diff --quiet && git -C "$REPO_ROOT" diff --cached --quiet; then
        success "No uncommitted changes"
    else
        info "Uncommitted changes present"
    fi
    
    # Check if gitignore exists
    if [[ -f "$REPO_ROOT/.gitignore" ]]; then
        success ".gitignore found"
        
        # Check for essential ignores
        local essential_ignores=("result" "*.qcow2" "secrets.yaml")
        for ignore in "${essential_ignores[@]}"; do
            if grep -q "$ignore" "$REPO_ROOT/.gitignore"; then
                success "$ignore in .gitignore"
            else
                warning "$ignore missing from .gitignore"
            fi
        done
    else
        warning ".gitignore missing"
    fi
    
    return $issues
}

# Generate health report
generate_report() {
    local total_issues=0
    local report_file="$REPO_ROOT/health-report-$(date +%Y%m%d-%H%M%S).txt"
    
    exec > >(tee "$report_file")
    
    echo "========================================="
    echo "NixOS Configuration Health Report"
    echo "Date: $(date)"
    echo "Repository: $REPO_ROOT"
    echo "========================================="
    echo
    
    check_auto_discovery || ((total_issues+=$?))
    echo
    
    check_secrets_health || ((total_issues+=$?))
    echo
    
    check_config_consistency || ((total_issues+=$?))
    echo
    
    check_build_optimization || ((total_issues+=$?))
    echo
    
    check_documentation || ((total_issues+=$?))
    echo
    
    check_system_resources || ((total_issues+=$?))
    echo
    
    check_git_health || ((total_issues+=$?))
    echo
    
    echo "========================================="
    echo "Health Check Summary"
    echo "========================================="
    
    if [[ $total_issues -eq 0 ]]; then
        success "All health checks passed! 🎉"
        echo "Report saved to: $report_file"
        exit 0
    else
        warning "$total_issues issue(s) found"
        echo "Report saved to: $report_file"
        echo
        echo "Recommendations:"
        echo "- Review the issues above"
        echo "- Run specific checks with: $0 <check-name>"
        echo "- Run full tests with: ./scripts/test-all.sh"
        exit 1
    fi
}

# CLI interface
case "${1:-all}" in
    "discovery")
        check_auto_discovery
        ;;
    "secrets")
        check_secrets_health
        ;;
    "consistency")
        check_config_consistency
        ;;
    "optimization")
        check_build_optimization
        ;;
    "docs")
        check_documentation
        ;;
    "resources")
        check_system_resources
        ;;
    "git")
        check_git_health
        ;;
    "all"|*)
        generate_report
        ;;
esac
