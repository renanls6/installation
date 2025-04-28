#!/bin/bash
set -e  # If any command fails, the script stops

# Styles
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

echo "🚀 Starting full setup (Node.js + Python venv)..."

# ─────────────────────────────────────────────────────
# Part 1: Install Node.js + npm
# ─────────────────────────────────────────────────────

# Check if curl is installed 
if ! command -v curl &> /dev/null; then
    show "curl is not installed. Installing curl..." "progress"
    sudo apt-get update
    sudo apt-get install -y curl
    if [ $? -ne 0 ]; then
        show "Failed to install curl. Please install it manually and rerun the script." "error"
        exit 1
    fi
fi

# Check for existing Node.js installations
EXISTING_NODE=$(which node)
if [ -n "$EXISTING_NODE" ]; then
    show "Existing Node.js found at $EXISTING_NODE. The script will install the latest version system-wide."
fi

# Fetch the latest Node.js version dynamically
show "Fetching latest Node.js version..." "progress"
LATEST_VERSION=$(curl -s https://nodejs.org/dist/latest/ | grep -oP 'node-v\K\d+\.\d+\.\d+' | head -1)
if [ -z "$LATEST_VERSION" ]; then
    show "Failed to fetch latest Node.js version. Please check your internet connection." "error"
    exit 1
fi
show "Latest Node.js version is $LATEST_VERSION"

# Extract the major version for NodeSource setup
MAJOR_VERSION=$(echo $LATEST_VERSION | cut -d. -f1)

# Set up the NodeSource repository
show "Setting up NodeSource repository for Node.js $MAJOR_VERSION.x..." "progress"
curl -sL https://deb.nodesource.com/setup_${MAJOR_VERSION}.x | sudo -E bash -
if [ $? -ne 0 ]; then
    show "Failed to set up NodeSource repository." "error"
    exit 1
fi

# Install Node.js and npm
show "Installing Node.js and npm..." "progress"
sudo apt-get install -y nodejs
if [ $? -ne 0 ]; then
    show "Failed to install Node.js and npm." "error"
    exit 1
fi

# Verify installation
show "Verifying Node.js and npm installation..." "progress"
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    show "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully!"
else
    show "Installation completed, but node or npm not found in PATH." "error"
    exit 1
fi

# ─────────────────────────────────────────────────────
# Part 2: Set up Python environment (rl-swarm)
# ─────────────────────────────────────────────────────

echo "🚀 Starting Python rl-swarm environment setup..."

# Create venv if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "⚙️  Creating virtual environment .venv..."
    python3 -m venv .venv
fi

# Activate the venv
echo "⚙️  Activating virtual environment..."
source .venv/bin/activate

# Update pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Uninstall wrong torch versions (if any)
echo "🧹 Cleaning up old torch installations..."
pip uninstall -y torch torchvision torchaudio || true

# Install correct PyTorch version (CUDA 12.1), torchvision, torchaudio
echo "📦 Installing torch 2.2.2 + CUDA 12.1..."
pip install torch==2.2.2+cu121 torchvision==0.17.2+cu121 torchaudio==2.2.2+cu121 --extra-index-url https://download.pytorch.org/whl/cu121

# Fix NumPy version
echo "🔧 Installing NumPy 1.26.4..."
pip install numpy==1.26.4

# Install additional required packages
echo "📦 Installing additional packages (hivemind, transformers, trl)..."
pip install hivemind transformers trl

# Final verification
echo "✅ Verifying PyTorch and CUDA installation..."
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"

echo "🏁 Setup COMPLETED! Node.js + Python environment is ready to use."
