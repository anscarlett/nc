#!/usr/bin/env bash
# Validate the NixOS configuration structure and detect common issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Validating NixOS configuration structure..."

# Check for required directories
required_dirs=("hosts" "homes" "modules" "lib" "outputs")
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$REPO_ROOT/$dir" ]]; then
        echo "❌ Required directory missing: $dir"
        exit 1
    fi
done

# Check for required files
required_files=("flake.nix")
for file in "${required_files[@]}"; do
    if [[ ! -f "$REPO_ROOT/$file" ]]; then
        echo "❌ Required file missing: $file"
        exit 1
    fi
done

# Check for host configurations
echo "📁 Checking host configurations..."
host_count=0
if [[ -d "$REPO_ROOT/hosts" ]]; then
    while IFS= read -r -d '' host_file; do
        echo "  ✅ Found host: $(dirname "$host_file" | xargs basename)"
        ((host_count++))
    done < <(find "$REPO_ROOT/hosts" -name "host.nix" -print0)
fi

if [[ $host_count -eq 0 ]]; then
    echo "⚠️  No host configurations found"
else
    echo "  📊 Total hosts: $host_count"
fi

# Check for home configurations
echo "🏠 Checking home configurations..."
home_count=0
if [[ -d "$REPO_ROOT/homes" ]]; then
    while IFS= read -r -d '' home_file; do
        echo "  ✅ Found home: $(dirname "$home_file" | xargs basename)"
        ((home_count++))
    done < <(find "$REPO_ROOT/homes" -name "home.nix" -print0)
fi

if [[ $home_count -eq 0 ]]; then
    echo "⚠️  No home configurations found"
else
    echo "  📊 Total homes: $home_count"
fi

# Check for syntax issues in main files
echo "🔧 Checking syntax..."
if command -v nix &> /dev/null; then
    if nix flake check --no-build 2>/dev/null; then
        echo "  ✅ Flake syntax is valid"
    else
        echo "  ❌ Flake syntax has issues"
        exit 1
    fi
else
    echo "  ⚠️  Nix not available, skipping syntax check"
fi

echo "✅ Configuration validation complete!"
