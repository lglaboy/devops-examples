#!/bin/bash
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
DEFAULT_BASE_URL="http://localhost:8080"
CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/config.json"
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed."
        print_info "Please install jq:"
        print_info "  macOS: brew install jq"
        print_info "  Ubuntu/Debian: sudo apt-get install jq"
        print_info "  CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
}
check_claude_code() {
    if command -v claude &> /dev/null; then
        local version=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code is already installed: $version"
        return 0
    else
        return 1
    fi
}
check_nodejs() {
    if command -v node &> /dev/null; then
        local version=$(node --version 2>/dev/null || echo "unknown")
        if [[ "$version" =~ ^v?([0-9]+) ]]; then
            local major_version="${BASH_REMATCH[1]}"
            if [ "$major_version" -ge 18 ]; then
                print_success "Node.js is installed: $version"
                return 0
            else
                print_warning "Node.js version is too old: $version (requires >= 18.0.0)"
                return 1
            fi
        fi
    fi
    return 1
}
install_nodejs() {
    print_info "Installing Node.js..."
    local os_type="$(uname -s)"
    if [ "$os_type" = "Darwin" ]; then
        if command -v brew &> /dev/null; then
            print_info "Installing Node.js using Homebrew..."
            brew install node
            return $?
        else
            print_warning "Homebrew not found. Please install Node.js manually from: https://nodejs.org/"
            return 1
        fi
    elif [ "$os_type" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            print_info "Installing Node.js using apt..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            return $?
        elif command -v yum &> /dev/null; then
            print_info "Installing Node.js using yum..."
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo yum install -y nodejs
            return $?
        else
            print_warning "Package manager not found. Please install Node.js manually from: https://nodejs.org/"
            return 1
        fi
    else
        print_warning "Unsupported OS. Please install Node.js manually from: https://nodejs.org/"
        return 1
    fi
}
install_claude_code() {
    print_info "Installing Claude Code CLI..."
    if ! command -v npm &> /dev/null; then
        print_error "npm is not available. Please restart your terminal after Node.js installation."
        return 1
    fi
    local npm_version=$(npm --version 2>/dev/null || echo "unknown")
    print_info "npm version: $npm_version"
    print_info "Running: npm install -g @anthropic-ai/claude-code"
    npm install -g @anthropic-ai/claude-code
    if [ $? -eq 0 ]; then
        if command -v claude &> /dev/null; then
            local version=$(claude --version 2>/dev/null || echo "unknown")
            print_success "Claude Code installed successfully: $version"
            return 0
        else
            print_warning "Claude Code was installed but cannot be verified. You may need to restart your terminal."
            return 0
        fi
    else
        print_error "Failed to install Claude Code"
        return 1
    fi
}
ensure_claude_code() {
    print_info "Checking Claude Code installation..."
    if check_claude_code; then
        return 0
    fi
    print_warning "Claude Code is not installed"
    if ! check_nodejs; then
        if ! install_nodejs; then
            print_warning "Failed to install Node.js automatically"
            return 1
        fi
    fi
    if install_claude_code; then
        return 0
    else
        print_warning "Failed to install Claude Code automatically"
        return 1
    fi
}
backup_settings() {
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        local backup_file="${CLAUDE_SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLAUDE_SETTINGS_FILE" "$backup_file"
        print_info "Backed up existing settings to: $backup_file"
    fi
}
create_settings_dir() {
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        mkdir -p "$CLAUDE_CONFIG_DIR"
        print_info "Created Claude configuration directory: $CLAUDE_CONFIG_DIR"
    fi
    if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
        touch "$CLAUDE_CONFIG_FILE"
        create_config
    fi
}
validate_api_key() {
    local api_key="$1"
    if [[ ! "$api_key" =~ ^[A-Za-z0-9_-]+$ ]]; then
        print_error "Invalid API key format. API key should contain only alphanumeric characters, hyphens, and underscores."   
        return 1
    fi
    return 0
}
test_api_connection() {
    local base_url="$1"
    local api_key="$2"
    print_info "Testing API connection..."
    local test_endpoint
    local balance_field
    test_endpoint="$base_url/health"
    balance_field="status"
    local response
    response=$(curl -s -w "%{http_code}" -o /tmp/claude_test_response \
        -X GET "$test_endpoint" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $api_key" \
        2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        local balance
        balance=$(cat /tmp/claude_test_response | jq -r ".${balance_field}" 2>/dev/null || echo "unknown")
        if [[ "$balance" == "ok" ]]; then
            print_success "API connection successful! "
        else
            print_success "API connection successful! Current balance: \$${balance}"
        fi
        rm -f /tmp/claude_test_response
        return 0
    elif [ "$response" = "401" ]; then
        print_error "API key authentication failed. Please check your API key."
        rm -f /tmp/claude_test_response
        return 1
    elif [ "$response" = "000" ]; then
        print_error "Cannot connect to API server. Please check the URL and your internet connection."
        rm -f /tmp/claude_test_response
        return 1
    else
        print_error "API test failed with HTTP status: $response"
        rm -f /tmp/claude_test_response
        return 1
    fi
}
create_settings() {
    local base_url="$1"
    local api_key="$2"
    local settings_json
    settings_json=$(cat <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "DISABLE_TELEMETRY": 1,
    "DISABLE_ERROR_REPORTING": 1,
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": 1
  },
  "model": "sonnet"
}
EOF
    )
    if ! echo "$settings_json" | jq . > /dev/null 2>&1; then
        print_error "Generated settings JSON is invalid"
        return 1
    fi
    echo "$settings_json" > "$CLAUDE_SETTINGS_FILE"
    print_success "Claude Code settings written to: $CLAUDE_SETTINGS_FILE"
}
create_config() {
    local config_json
    config_json=$(cat <<EOF
{
  "primaryApiKey": "claudecode"
}
EOF
    )
    echo "$config_json" > "$CLAUDE_CONFIG_FILE"
}
display_settings() {
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        print_info "Current Claude Code settings:"
        echo "----------------------------------------"
        cat "$CLAUDE_SETTINGS_FILE" | jq .
        echo "----------------------------------------"
    else
        print_info "No existing Claude Code settings found."
    fi
}
main() {
    print_info "Claude Code Configuration Script"
    echo "======================================================="
    echo
    check_jq
    local skip_install=false
    for arg in "$@"; do
        if [[ "$arg" == "-s" ]] || [[ "$arg" == "--show" ]] || [[ "$arg" == "-t" ]] || [[ "$arg" == "--test" ]]; then
            skip_install=true
            break
        fi
    done
    if [ "$skip_install" = false ]; then
        ensure_claude_code || true
        echo
    fi
    local base_url=""
    local api_key=""
    local test_only=false
    local show_settings=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                base_url="$2"
                shift 2
                ;;
            -k|--key)
                api_key="$2"
                shift 2
                ;;
            -t|--test)
                test_only=true
                shift
                ;;
            -s|--show)
                show_settings=true
                shift
                ;;
            -h|--help)
                cat <<EOF
Usage: $0 [OPTIONS]
Options:
  -u, --url URL     Set the base URL (default: $DEFAULT_BASE_URL)
  -k, --key KEY     Set the API key
  -t, --test        Test API connection only (requires -u and -k)
  -s, --show        Show current settings and exit
  -h, --help        Show this help message
Examples:
  $0 --url https://your-domain.tld --key your-api-key-here
  $0 --test --url https://your-domain.tld --key your-api-key-here
  $0 --show
Interactive mode (no arguments):
  $0
EOF
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    if [ "$show_settings" = true ]; then
        display_settings
        exit 0
    fi
    if [ -z "$base_url" ] && [ -z "$api_key" ]; then
        print_info "Interactive setup mode"
        echo
        read -p "Enter Base URL [$DEFAULT_BASE_URL]: " base_url
        if [ -z "$base_url" ]; then
            base_url="$DEFAULT_BASE_URL"
        fi
        while [ -z "$api_key" ]; do
            read -p "Enter your API key: " api_key
            if [ -z "$api_key" ]; then
                print_warning "API key is required"
            elif ! validate_api_key "$api_key"; then
                api_key=""
            fi
        done
    fi
    if [ -z "$base_url" ] || [ -z "$api_key" ]; then
        print_error "Both URL and API key are required"
        print_info "Use --help for usage information"
        exit 1
    fi
    if ! validate_api_key "$api_key"; then
        exit 1
    fi
    base_url="${base_url%/}"
    print_info "Configuration:"
    print_info "  Base URL: $base_url"
    print_info "  API Key: ${api_key:0:8}...${api_key: -4}"
    echo
    if ! test_api_connection "$base_url" "$api_key"; then
        if [ "$test_only" = true ]; then
            exit 1
        fi
        read -p "API test failed. Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled"
            exit 1
        fi
    fi
    if [ "$test_only" = true ]; then
        print_success "API test completed successfully"
        exit 0
    fi
    create_settings_dir
    backup_settings
    if create_settings "$base_url" "$api_key"; then
        echo
        print_success "Configuration has been saved successfully!"
        print_info "Configuration file location: $CLAUDE_SETTINGS_FILE"
        echo
        if command -v claude &> /dev/null; then
            print_success "Claude Code is installed and ready to use!"
            print_info "Run 'claude --version' to verify"
        else
            print_warning "Claude Code not installed. To install manually:"
            print_info "1. Install Node.js from https://nodejs.org/"
            print_info "2. Run: npm install -g @anthropic-ai/claude-code"
        fi
        if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
            echo
            print_info "Current settings:"
            cat "$CLAUDE_SETTINGS_FILE" | jq .
        fi
    else
        print_error "Failed to create Claude Code settings"
        exit 1
    fi
}
main "$@"