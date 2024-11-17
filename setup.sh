#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root (use sudo)"
fi

# Welcome message
log "Starting Asset Management Application Setup..."
log "This script will install and configure all necessary components."

# System update
log "Updating system packages..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    apt-get update -y || error "Failed to update system packages"
    apt-get upgrade -y || warning "Some packages might not be upgraded"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew update || error "Failed to update Homebrew"
    brew upgrade || warning "Some packages might not be upgraded"
else
    warning "Unsupported operating system. Package updates skipped."
fi

# Install dependencies based on OS
install_dependencies() {
    log "Installing required dependencies..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install Go
        if ! command -v go &> /dev/null; then
            log "Installing Go..."
            wget https://golang.org/dl/go1.21.1.linux-amd64.tar.gz || error "Failed to download Go"
            rm -rf /usr/local/go
            tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz || error "Failed to extract Go"
            export PATH=$PATH:/usr/local/go/bin
            echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
            rm go1.21.1.linux-amd64.tar.gz
        else
            success "Go is already installed"
        fi

        # Install MongoDB
        if ! command -v mongod &> /dev/null; then
            log "Installing MongoDB..."
            wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
            echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            apt-get update
            apt-get install -y mongodb-org || error "Failed to install MongoDB"
            systemctl start mongod
            systemctl enable mongod
        else
            success "MongoDB is already installed"
        fi

        # Install Nmap
        if ! command -v nmap &> /dev/null; then
            log "Installing Nmap..."
            apt-get install -y nmap || error "Failed to install Nmap"
        else
            success "Nmap is already installed"
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Install Homebrew if not installed
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install Homebrew"
        fi

        # Install Go
        if ! command -v go &> /dev/null; then
            log "Installing Go..."
            brew install go || error "Failed to install Go"
        else
            success "Go is already installed"
        fi

        # Install MongoDB
        if ! command -v mongod &> /dev/null; then
            log "Installing MongoDB..."
            brew tap mongodb/brew
            brew install mongodb-community || error "Failed to install MongoDB"
            brew services start mongodb-community
        else
            success "MongoDB is already installed"
        fi

        # Install Nmap
        if ! command -v nmap &> /dev/null; then
            log "Installing Nmap..."
            brew install nmap || error "Failed to install Nmap"
        else
            success "Nmap is already installed"
        fi
    else
        error "Unsupported operating system"
    fi
}

# Create project structure
create_project_structure() {
    log "Creating project structure..."
    
    # Create base directory
    PROJECT_DIR="/opt/argusred"
    mkdir -p $PROJECT_DIR/{config,models,services,handlers} || error "Failed to create project directories"
    
    # Set proper permissions
    chown -R $(who am i | awk '{print $1}') $PROJECT_DIR
    chmod -R 755 $PROJECT_DIR
    
    success "Project structure created at $PROJECT_DIR"
}

# Initialize MongoDB
initialize_mongodb() {
    log "Initializing MongoDB..."
    
    # Wait for MongoDB to be ready
    sleep 5
    
    mongosh <<EOF || error "Failed to initialize MongoDB"
use asset_management
db.createCollection("assets")
db.createUser({
    user: "assetmgr",
    pwd: "$(openssl rand -base64 12)",
    roles: [{ role: "readWrite", db: "asset_management" }]
})
EOF
    
    success "MongoDB initialized successfully"
}

# Set up environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    # Create environment file
    cat > /etc/argusred.env << EOF
MONGO_URI="mongodb://localhost:27017"
DB_NAME="asset_management"
SERVER_ADDR=":8080"
EOF
    
    # Add to profile
    echo "source /etc/argusred.env" >> /etc/profile
    
    success "Environment variables configured"
}

# Create systemd service
create_service() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log "Creating systemd service..."
        
        cat > /etc/systemd/system/argusred.service << EOF
[Unit]
Description=Asset Management Service
After=network.target mongodb.service

[Service]
Type=simple
User=$(who am i | awk '{print $1}')
EnvironmentFile=/etc/argusred.env
WorkingDirectory=/opt/argusred
ExecStart=/opt/argusred/argusred
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable argusred.service
        
        success "Systemd service created"
    fi
}

# Main installation process
main() {
    install_dependencies
    create_project_structure
    initialize_mongodb
    setup_environment
    create_service
    
    success "Installation completed successfully!"
    
    # Print usage instructions
    cat << EOF

${GREEN}=== ArgusRED Application Installed ===${NC}

Configuration file: /etc/argusred.env
Application directory: /opt/argusred
MongoDB database: asset_management

To start the application:
    sudo systemctl start argusred

To check status:
    sudo systemctl status argusred

To view logs:
    sudo journalctl -u argusred -f

To test the installation:
    curl http://localhost:8080/health

For importing Nmap scans:
    nmap -A -oX scan.xml <target>
    curl -X POST -F "scan=@scan.xml" -F "environment=production" http://localhost:8080/api/import/nmap

EOF
}

# Error handling for the entire script
set -e
trap 'error "An error occurred during installation. Please check the logs."' ERR

# Run main installation
main

exit 0