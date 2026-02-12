#!/bin/bash
set -e

echo "Installing prerequisites for Introspect 2B..."

if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."
  brew install awscli
else
  echo "✅ AWS CLI already installed"
fi

if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  brew install kubectl
else
  echo "✅ kubectl already installed"
fi

if ! command -v eksctl &> /dev/null; then
  echo "Installing eksctl..."
  brew tap weaveworks/tap
  brew install weaveworks/tap/eksctl
else
  echo "✅ eksctl already installed"
fi

if ! command -v helm &> /dev/null; then
  echo "Installing Helm..."
  brew install helm
else
  echo "✅ Helm already installed"
fi

if ! command -v docker &> /dev/null; then
  echo "Installing Docker Desktop..."
  brew install --cask docker
  echo "⚠️  Start Docker Desktop manually after install"
else
  echo "✅ Docker already installed"
fi

echo ""
echo "Verification:"
aws --version || true
kubectl version --client --short 2>/dev/null || true
eksctl version || true
helm version --short 2>/dev/null || true
docker --version || true

echo ""
echo "✅ Prerequisites installation completed"
