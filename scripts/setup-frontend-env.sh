#!/bin/bash

# Frontend Environment Setup Script
# Usage: curl -fsSL <script-url> | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0
NPMRC_BACKUP_PATH=""

HUMA_NPM_REGISTRY_PREFIX="@huma-engineering:registry"
HUMA_NPM_REGISTRY_VALUE="https://npm.pkg.github.com"
HUMA_NPM_REGISTRY="$HUMA_NPM_REGISTRY_PREFIX=$HUMA_NPM_REGISTRY_VALUE"
HUMA_NPM_TOKEN_PREFIX="//npm.pkg.github.com/:_authToken="

# Print banner
print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Frontend Environment Setup - Huma Engineering       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print step header
print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step $CURRENT_STEP/$TOTAL_STEPS: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Print info
print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get shell profile file
get_shell_profile() {
    local current_shell
    current_shell=$(basename "$SHELL")

    if [[ "$current_shell" == "zsh" ]]; then
        echo "$HOME/.zshrc"
    elif [[ "$current_shell" == "bash" ]]; then
        # Check for existing bash files (Linux prefers .bashrc, macOS prefers .bash_profile)
        if [[ -f "$HOME/.bashrc" ]]; then
            echo "$HOME/.bashrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            echo "$HOME/.bash_profile"
        else
            # Default fallback for bash if neither exists
            echo "$HOME/.bashrc"
        fi
    elif [[ "$current_shell" == "fish" ]]; then
        echo "$HOME/.config/fish/config.fish"
    else
        # Generic fallback for sh, dash, ksh, etc.
        echo "$HOME/.profile"
    fi
}

# Step 1: Install NVM
install_nvm() {
    print_step "Install NVM (Node Version Manager)"
    
    if [ -d "$HOME/.nvm" ]; then
        print_warning "NVM directory already exists at ~/.nvm"
        
        # Source NVM to check if it's functional
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command_exists nvm; then
            print_success "NVM is already installed (version: $(nvm --version))"
            return 0
        else
            print_warning "NVM directory exists but command not found. Reinstalling..."
        fi
    fi
    
    print_info "Downloading and installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    if command_exists nvm; then
        print_success "NVM installed successfully (version: $(nvm --version))"
        print_info "Shell profile updated: $(get_shell_profile)"
    else
        print_error "NVM installation failed"
        exit 1
    fi
}

# Step 2: Install Node.js LTS
install_nodejs() {
    print_step "Install Node.js LTS"
    
    # Ensure NVM is loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command_exists nvm; then
        print_error "NVM not found. Please restart your terminal and run this script again."
        exit 1
    fi
    
    # Check if Node.js LTS is already installed
    if command_exists node; then
        local current_version=$(node --version)
        print_warning "Node.js $current_version is already installed"
        
        # Check if it's set as default
        local default_version=$(nvm version default 2>/dev/null || echo "none")
        if [ "$default_version" = "none" ]; then
            print_info "Setting current Node.js version as default..."
            nvm alias default node
        fi
        
        print_success "Node.js: $current_version"
        print_success "npm: $(npm --version)"
        return 0
    fi
    
    print_info "Installing Node.js LTS..."
    nvm install --lts
    
    print_info "Setting LTS as default..."
    nvm alias default 'lts/*'
    nvm use default
    
    if command_exists node && command_exists npm; then
        print_success "Node.js installed: $(node --version)"
        print_success "npm installed: $(npm --version)"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Step 3: Get GitHub Token
get_github_token() {
    print_step "Configure GitHub Personal Access Token"
    
    local npmrc_file="$HOME/.npmrc"
    local has_registry=false
    local has_token=false

    if [ -f "$npmrc_file" ]; then
        if grep -q "^$HUMA_NPM_REGISTRY" "$npmrc_file"; then
            has_registry=true
        fi

        if grep -q "^$token_prefix" "$npmrc_file"; then
            has_token=true
        fi
    fi
    
    # Check if registry and token already exist in .npmrc
    if [ "$has_registry" = true ] && [ "$has_token" = true ]; then
        print_success "GitHub registry and token already configured in ~/.npmrc"
        return 0
    fi

    if [ "$has_registry" != true ]; then
        print_warning "GitHub registry entry missing in ~/.npmrc"
    fi

    if [ "$has_token" != true ]; then
        print_warning "GitHub token missing in ~/.npmrc"
    fi
    
    print_info "GitHub Personal Access Token (classic) is needed for private packages."
    print_info "The token should have 'read:packages' and 'repo' scopes."
    echo ""
    
    # Prompt for token
    echo -n "Enter your GitHub Personal Access Token (or press Enter to skip): "
    read -s github_token
    echo ""
    
    if [ -z "$github_token" ]; then
        print_warning "No token provided. You'll need to manually configure ~/.npmrc."
        print_info "Add these lines to ~/.npmrc:"
        echo ""
        echo "$HUMA_NPM_REGISTRY"
        echo "${token_prefix}YOUR_GITHUB_TOKEN"
        echo ""
        return 0
    fi
    
    # Backup existing .npmrc if it exists
    if [ -f "$npmrc_file" ]; then
        local backup_file="$npmrc_file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$npmrc_file" "$backup_file"
        print_info "Existing .npmrc backed up to $backup_file"
        NPMRC_BACKUP_PATH="$backup_file"
    fi
    
    # Ensure npmrc exists before editing
    touch "$npmrc_file"

    # Ensure registry line exists
    if ! grep -q "^$HUMA_NPM_REGISTRY" "$npmrc_file" 2>/dev/null; then
        printf "\n%s\n" "$HUMA_NPM_REGISTRY" >> "$npmrc_file"
    fi

    # Add or update token line without replacing the rest of the file
    local token_line="${token_prefix}${github_token}"
    if grep -q "^$token_prefix" "$npmrc_file" 2>/dev/null; then
        if command_exists perl; then
            perl -0pi -e 's|^//npm\.pkg\.github\.com/:_authToken=.*$|'"$token_line"'|m' "$npmrc_file"
        else
            tmp_file=$(mktemp)
            awk -v token_line="$token_line" '
                BEGIN { replaced=0 }
                {
                    if ($0 ~ /^\/\/npm\.pkg\.github\.com\/:_authToken=/ && replaced == 0) {
                        print token_line
                        replaced = 1
                    } else {
                        print
                    }
                }
            ' "$npmrc_file" > "$tmp_file"
            mv "$tmp_file" "$npmrc_file"
        fi
    else
        printf "\n%s\n" "$token_line" >> "$npmrc_file"
    fi

    print_success "GitHub token configured in ~/.npmrc"
}

# Step 4: Install Angular CLI
install_angular_cli() {
    print_step "Install Angular CLI 20.0.0"
    
    # Check if Angular CLI is already installed
    if command_exists ng; then
        local current_version=$(ng version 2>/dev/null | grep "Angular CLI" | awk '{print $3}')
        
        if [ ! -z "$current_version" ]; then
            print_warning "Angular CLI $current_version is already installed"
            
            if [[ "$current_version" == "20.0.0" ]]; then
                print_success "Angular CLI 20.0.0 is already installed"
                return 0
            else
                print_info "Updating to version 20.0.0..."
            fi
        fi
    fi
    
    print_info "Installing Angular CLI 20.0.0 globally..."
    npm install -g @angular/cli@20.0.0
    
    if command_exists ng; then
        local installed_version=$(ng version 2>/dev/null | grep "Angular CLI" | awk '{print $3}')
        print_success "Angular CLI installed: $installed_version"
    else
        print_error "Angular CLI installation failed"
        exit 1
    fi
}

# Step 5: Final Verification
final_verification() {
    print_step "Final Verification"
    
    echo ""
    print_info "Checking all installations..."
    echo ""
    
    local all_good=true
    
    # NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists nvm; then
        print_success "NVM: $(nvm --version)"
    else
        print_error "NVM: Not found"
        all_good=false
    fi
    
    # Node.js
    if command_exists node; then
        print_success "Node.js: $(node --version)"
    else
        print_error "Node.js: Not found"
        all_good=false
    fi
    
    # npm
    if command_exists npm; then
        print_success "npm: $(npm --version)"
    else
        print_error "npm: Not found"
        all_good=false
    fi
    
    # Angular CLI
    if command_exists ng; then
        local ng_version=$(ng version 2>/dev/null | grep "Angular CLI" | awk '{print $3}')
        print_success "Angular CLI: $ng_version"
    else
        print_error "Angular CLI: Not found"
        all_good=false
    fi
    
    # .npmrc
    if [ -f "$HOME/.npmrc" ]; then
        print_success ".npmrc: Configured"
        if [ -n "$NPMRC_BACKUP_PATH" ]; then
            print_info "Previous .npmrc backup saved at $NPMRC_BACKUP_PATH"
        fi

        if [[ "$(npm config get $HUMA_NPM_REGISTRY_PREFIX)" == *"$HUMA_NPM_REGISTRY_VALUE"* ]]; then
            print_success "GitHub registry entry correctly set in npm config"
        else
            print_warning "GitHub registry entry not found in npm config (you may need to configure it manually)"
        fi

        if npm whoami --registry="$HUMA_NPM_REGISTRY_VALUE" >/dev/null 2>&1; then
            print_success "GitHub token is valid and working"
        else
            print_warning "GitHub token may not be working (you may need to configure it manually)"
        fi
    else
        print_warning ".npmrc: Not found (you may need to configure it manually)"
    fi
    
    echo ""
    
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║            🎉 Setup completed successfully! 🎉             ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        print_info "Next steps:"
        echo "  1. Restart your terminal or run: source $(get_shell_profile)"
        echo "  2. Create a new Angular project with 'craft-cli' or clone an existing project"
        echo ""
    else
        print_error "Some components failed to install. Please check the errors above."
        exit 1
    fi
}

# Main execution
main() {
    print_banner
    
    # Check if running on supported OS
    if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is designed for macOS and Linux only."
        print_info "For Windows, please use WSL (Windows Subsystem for Linux)."
        exit 1
    fi
    
    install_nvm
    install_nodejs
    get_github_token
    install_angular_cli
    final_verification
    
    echo ""
    print_success "All done! Happy coding! 🚀"
    echo ""
}

# Run main function
main
