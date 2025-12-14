#!/bin/bash

# Documentation Verification Script
# This script helps verify the integrity and completeness of the Euystacio Framework documentation

set -e

echo "================================================"
echo "Euystacio Framework - Documentation Verification"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        ((ERRORS++))
        return 1
    fi
}

# Function to check if directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ - MISSING"
        ((ERRORS++))
        return 1
    fi
}

echo "Checking documentation structure..."
echo ""

# Check main README
check_file "README.md"

# Check docs directory
check_dir "docs"

# Check main documentation files
echo ""
echo "Checking main documentation files..."
check_file "docs/EUYSTACIO_FRAMEWORK_MASTER.md"

# Check subdirectories
echo ""
echo "Checking subdirectories..."
check_dir "docs/governance"
check_dir "docs/architecture"
check_dir "docs/roadmap"
check_dir "docs/distribution"
check_dir "docs/community"

# Check subdirectory READMEs
echo ""
echo "Checking subdirectory documentation..."
check_file "docs/governance/README.md"
check_file "docs/architecture/README.md"
check_file "docs/roadmap/README.md"
check_file "docs/distribution/README.md"
check_file "docs/community/README.md"

# Check scripts
echo ""
echo "Checking deployment scripts..."
check_dir "scripts"
check_file "scripts/README.md"
check_file "scripts/deploy-to-ipfs.sh"
check_file "scripts/EuystacioDocumentAnchor.sol"
check_file "scripts/DEPLOYMENT_GUIDE.md"

# Check if deploy script is executable
if [ -f "scripts/deploy-to-ipfs.sh" ]; then
    if [ -x "scripts/deploy-to-ipfs.sh" ]; then
        echo -e "${GREEN}✓${NC} scripts/deploy-to-ipfs.sh is executable"
    else
        echo -e "${YELLOW}!${NC} scripts/deploy-to-ipfs.sh is not executable"
        echo "  Run: chmod +x scripts/deploy-to-ipfs.sh"
        ((WARNINGS++))
    fi
fi

# Check .gitignore
echo ""
echo "Checking configuration files..."
check_file ".gitignore"

# Validate markdown syntax (basic check)
echo ""
echo "Validating markdown files..."
for file in docs/EUYSTACIO_FRAMEWORK_MASTER.md docs/*/README.md; do
    if [ -f "$file" ]; then
        # Check for basic markdown issues
        if grep -q "^#" "$file"; then
            echo -e "${GREEN}✓${NC} $file has headers"
        else
            echo -e "${YELLOW}!${NC} $file has no headers"
            ((WARNINGS++))
        fi
        
        # Check file is not empty
        if [ -s "$file" ]; then
            echo -e "${GREEN}✓${NC} $file is not empty"
        else
            echo -e "${RED}✗${NC} $file is empty"
            ((ERRORS++))
        fi
    fi
done

# Check for broken internal links
echo ""
echo "Checking internal links in README.md..."
if [ -f "README.md" ]; then
    # Extract relative links
    while IFS= read -r link; do
        # Extract the path from markdown link
        path=$(echo "$link" | sed -n 's/.*](\(\.\/[^)]*\)).*/\1/p')
        if [ -n "$path" ]; then
            # Remove leading ./
            clean_path="${path#./}"
            if [ -f "$clean_path" ]; then
                echo -e "${GREEN}✓${NC} Link OK: $path"
            else
                echo -e "${RED}✗${NC} Broken link: $path"
                ((ERRORS++))
            fi
        fi
    done < <(grep -o "\[.*\](\.\/[^)]*)" README.md || true)
fi

# Check for broken internal links in master document
echo ""
echo "Checking internal links in master document..."
if [ -f "docs/EUYSTACIO_FRAMEWORK_MASTER.md" ]; then
    cd docs
    while IFS= read -r link; do
        # Extract the path from markdown link
        path=$(echo "$link" | sed -n 's/.*](\(\.\/[^)]*\)).*/\1/p')
        if [ -n "$path" ]; then
            # Remove leading ./
            clean_path="${path#./}"
            if [ -f "$clean_path" ]; then
                echo -e "${GREEN}✓${NC} Link OK: $path"
            else
                echo -e "${RED}✗${NC} Broken link: $path"
                ((ERRORS++))
            fi
        fi
    done < <(grep -o "\[.*\](\.\/[^)]*)" EUYSTACIO_FRAMEWORK_MASTER.md || true)
    cd ..
fi

# Summary
echo ""
echo "================================================"
echo "Verification Summary"
echo "================================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Documentation is complete and ready for distribution."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}! $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Documentation is mostly complete but has some warnings."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}! $WARNINGS warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors before distribution."
    exit 1
fi
