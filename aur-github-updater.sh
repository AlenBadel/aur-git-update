#!/bin/bash
# AUR Package Updater via GitHub Mirror
# Updates AUR packages from https://github.com/archlinux/aur when AUR is down
# Usage: ./aur-github-updater.sh [--dry-run] [--force]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORK_DIR="${TMPDIR:-/tmp}/aur-github-updater-$$"
GITHUB_MIRROR="https://github.com/archlinux/aur.git"
DRY_RUN=false
FORCE_UPDATE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be updated without actually updating"
            echo "  --force      Force rebuild all packages even if versions match"
            echo "  --help       Display this help message"
            exit 0
            ;;
    esac
done

# Cleanup function
cleanup() {
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo -e "${BLUE}=== AUR Package Updater via GitHub Mirror ===${NC}"
echo ""

# Get list of AUR packages (foreign packages)
echo -e "${BLUE}Scanning for installed AUR packages...${NC}"
mapfile -t AUR_PACKAGES < <(pacman -Qqm)

if [ ${#AUR_PACKAGES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No AUR packages found.${NC}"
    exit 0
fi

echo -e "${GREEN}Found ${#AUR_PACKAGES[@]} AUR packages installed${NC}"
echo ""

# Statistics - Initialize to prevent set -e issues with arithmetic
UPDATED=0
SKIPPED=0
FAILED=0
declare -a FAILED_PACKAGES

# Process each package
for pkg in "${AUR_PACKAGES[@]}"; do
    echo -e "${BLUE}Checking: $pkg${NC}"

    # Get current installed version
    CURRENT_VERSION=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}') || true

    if [ -z "$CURRENT_VERSION" ]; then
        echo -e "${RED}  ✗ Could not determine current version${NC}"
        FAILED=$((FAILED + 1))
        FAILED_PACKAGES+=("$pkg")
        echo ""
        continue
    fi

    echo -e "  Current version: ${YELLOW}$CURRENT_VERSION${NC}"

    # Clone package from GitHub mirror
    echo -e "  Fetching from GitHub mirror..."
    if ! git clone --branch "$pkg" --single-branch --depth 1 "$GITHUB_MIRROR" "$pkg" &>/dev/null; then
        echo -e "${RED}  ✗ Failed to clone from GitHub mirror${NC}"
        echo -e "${YELLOW}  (Package might not exist in AUR or network issue)${NC}"
        FAILED=$((FAILED + 1))
        FAILED_PACKAGES+=("$pkg")
        echo ""
        continue
    fi

    cd "$pkg"

    # Extract version from PKGBUILD
    # Source the PKGBUILD in a subshell to extract variables
    if [ ! -f "PKGBUILD" ]; then
        echo -e "${RED}  ✗ PKGBUILD not found${NC}"
        cd ..
        FAILED=$((FAILED + 1))
        FAILED_PACKAGES+=("$pkg")
        echo ""
        continue
    fi

    # Parse PKGBUILD to get version
    # We need to source it carefully to extract pkgver, pkgrel, and epoch
    AVAILABLE_VERSION=$(bash -c '
        source PKGBUILD 2>/dev/null || exit 1
        if [ -n "$epoch" ]; then
            echo "$epoch:$pkgver-$pkgrel"
        else
            echo "$pkgver-$pkgrel"
        fi
    ') || true

    if [ -z "$AVAILABLE_VERSION" ]; then
        echo -e "${RED}  ✗ Could not parse PKGBUILD${NC}"
        cd ..
        FAILED=$((FAILED + 1))
        FAILED_PACKAGES+=("$pkg")
        echo ""
        continue
    fi

    echo -e "  Available version: ${GREEN}$AVAILABLE_VERSION${NC}"

    # Compare versions
    if [ "$CURRENT_VERSION" = "$AVAILABLE_VERSION" ] && [ "$FORCE_UPDATE" = false ]; then
        echo -e "${GREEN}  ✓ Already up to date${NC}"
        cd ..
        SKIPPED=$((SKIPPED + 1))
        echo ""
        continue
    fi

    # Version comparison using vercmp
    if [ "$FORCE_UPDATE" = false ]; then
        VERSION_CMP=$(vercmp "$AVAILABLE_VERSION" "$CURRENT_VERSION") || true
        if [ "$VERSION_CMP" -le 0 ]; then
            echo -e "${GREEN}  ✓ Installed version is newer or equal${NC}"
            cd ..
            SKIPPED=$((SKIPPED + 1))
            echo ""
            continue
        fi
    fi

    # Update needed
    echo -e "${YELLOW}  → Update available!${NC}"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}  [DRY RUN] Would update: $CURRENT_VERSION → $AVAILABLE_VERSION${NC}"
        cd ..
        UPDATED=$((UPDATED + 1))
        echo ""
        continue
    fi

    # Build and install
    echo -e "  Building package..."
    if makepkg -si --noconfirm --needed 2>&1 | tee makepkg.log; then
        echo -e "${GREEN}  ✓ Successfully updated: $CURRENT_VERSION → $AVAILABLE_VERSION${NC}"
        UPDATED=$((UPDATED + 1))
    else
        echo -e "${RED}  ✗ Build failed (see makepkg.log for details)${NC}"
        FAILED=$((FAILED + 1))
        FAILED_PACKAGES+=("$pkg")
    fi

    cd ..
    echo ""
done

# Summary
echo ""
echo -e "${BLUE}=== Update Summary ===${NC}"
echo -e "${GREEN}Updated: $UPDATED${NC}"
echo -e "${YELLOW}Skipped (up to date): $SKIPPED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed packages:${NC}"
    printf '  %s\n' "${FAILED_PACKAGES[@]}"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}This was a dry run. Use without --dry-run to apply updates.${NC}"
fi

exit 0
