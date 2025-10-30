#!/bin/bash

# Backend Connection Test Script
# Tests connectivity to ZDatar backend API

echo "🔍 ZDatar Backend Connection Test"
echo "=================================="
echo ""

# Get backend URL from .env file
if [ -f .env ]; then
    BACKEND_URL=$(grep "^API_BASE_URL=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
    echo "📡 Backend URL from .env: $BACKEND_URL"
else
    echo "⚠️  .env file not found"
    BACKEND_URL="http://20.198.241.60:3000"
    echo "📡 Using default: $BACKEND_URL"
fi

echo ""
echo "Testing connection..."
echo "-------------------"

# Test 1: Basic connectivity
echo "1️⃣  Testing basic connectivity..."
if curl -s --connect-timeout 5 "$BACKEND_URL" > /dev/null 2>&1; then
    echo "   ✅ Connection successful"
else
    echo "   ❌ Connection failed"
    echo "   💡 Possible issues:"
    echo "      • Backend server is not running"
    echo "      • Firewall blocking connection"
    echo "      • VPN or network issues"
    echo "      • Wrong IP address or port"
fi

echo ""

# Test 2: Health endpoint
echo "2️⃣  Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s --connect-timeout 5 "$BACKEND_URL/health" 2>&1)
if [ $? -eq 0 ]; then
    echo "   ✅ Health check successful"
    echo "   📄 Response: $HEALTH_RESPONSE"
else
    echo "   ❌ Health check failed"
fi

echo ""

# Test 3: Deals endpoint
echo "3️⃣  Testing /deals endpoint..."
DEALS_RESPONSE=$(curl -s --connect-timeout 5 "$BACKEND_URL/deals" 2>&1)
if [ $? -eq 0 ]; then
    echo "   ✅ Deals endpoint accessible"
    DEAL_COUNT=$(echo "$DEALS_RESPONSE" | grep -o '"deal_id"' | wc -l | tr -d ' ')
    echo "   📊 Found $DEAL_COUNT deals"
else
    echo "   ❌ Deals endpoint failed"
fi

echo ""

# Test 4: Test accept deal endpoint format
echo "4️⃣  Testing /deals/:id/accept endpoint format..."
DEAL_ID="test-deal-id"
echo "   Using test deal ID: $DEAL_ID"
ACCEPT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"buyer_wallet":"test-wallet-address"}' \
    --connect-timeout 5 \
    "$BACKEND_URL/deals/$DEAL_ID/accept" 2>&1)

if echo "$ACCEPT_RESPONSE" | grep -q "error"; then
    echo "   ⚠️  Endpoint exists (returned error as expected for test ID)"
    echo "   📄 Response: $ACCEPT_RESPONSE"
else
    echo "   ℹ️  Response: $ACCEPT_RESPONSE"
fi

echo ""
echo "=================================="
echo "💡 Troubleshooting Tips:"
echo "-------------------"
echo "• If connection fails:"
echo "  - Check if backend server is running"
echo "  - Verify API_BASE_URL in .env file"
echo "  - Test from browser: $BACKEND_URL/deals"
echo ""
echo "• For iOS Simulator:"
echo "  - Use: http://localhost:3000 (if backend on same machine)"
echo ""
echo "• For Physical Device:"
echo "  - Use: http://YOUR_COMPUTER_IP:3000"
echo "  - Ensure device and computer on same network"
echo "  - Check firewall allows incoming connections on port 3000"
echo ""
echo "• Azure VM (20.198.241.60):"
echo "  - Ensure port 3000 is open in Network Security Group"
echo "  - Check backend service is running on VM"
echo "  - Verify VM is not sleeping or stopped"
echo ""
