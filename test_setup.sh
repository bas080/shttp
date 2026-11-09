#!/bin/sh
# Test script to verify shttp server and client setup
# Make sure the scripts are executable

CLIENT="/home/bashbot/shttp/client/shttp"
SERVER="/home/bashbot/shttp/server/shttp.js"

cd /home/bashbot/shttp

echo "=== Checking files and permissions ==="

echo "Server file: $SERVER"
if [ -f "$SERVER" ]; then
    echo "  ✅ Exists"
    if [ -x "$SERVER" ]; then
        echo "  ✅ Executable"
    else
        echo "  ❌ Not executable"
    fi
else
    echo "  ❌ Missing"
fi

echo "Client file: $CLIENT"
if [ -f "$CLIENT" ]; then
    echo "  ✅ Exists"
    if [ -x "$CLIENT" ]; then
        echo "  ✅ Executable"
    else
        echo "  ❌ Not executable"
    fi
else
    echo "  ❌ Missing"
fi

echo ""
echo "=== Testing client directly (should try to connect, fail, exit non-zero) ==="

export SHTTP_ALLOWED_COMMANDS="echo"

echo "Test: $CLIENT echo test"
# This will try to connect to the server, which will fail
$CLIENT echo test
exit_code=$?

echo "Exit code: $exit_code"

if [ "$exit_code" -ne 0 ]; then
    echo "✅ Client script invoked successfully"
else
    echo "❌ Client script failed unexpectedly"
fi

echo ""
echo "=== Testing server startup with no whitelist (should fail) ==="

unset SHTTP_ALLOWED_COMMANDS
echo "Starting server without SHTTP_ALLOWED_COMMANDS..."
node "$SERVER" &
server_pid=$!
sleep 2

# Check if server process is still running
if ps -p "$server_pid" > /dev/null 2>&1; then
    echo "❌ Server should have exited when SHTTP_ALLOWED_COMMANDS is not set"
    kill "$server_pid" 2>/dev/null || true
else
    echo "✅ Server correctly exited when SHTTP_ALLOWED_COMMANDS is not configured"
fi

echo ""
echo "=== Testing server startup with whitelist ==="

export SHTTP_ALLOWED_COMMANDS="echo"
echo "Starting server with whitelist: echo"
node "$SERVER" &
server_pid=$!
sleep 2

# Check if server process is running
if ps -p "$server_pid" > /dev/null 2>&1; then
    echo "✅ Server is running with whitelist configured"
else
    echo "❌ Server failed to start with whitelist"
fi

echo ""
echo "=== Testing whitelist enforcement ==="

echo "Test 1: Allowed command 'echo hello'"
result=$("$CLIENT" echo hello 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -eq 0 ] && echo "$result" | grep -q "hello"; then
    echo "✅ Whitelist allows 'echo' command"
else
    echo "❌ Whitelist should allow 'echo' command"
fi

echo ""
echo "Test 2: Disallowed command 'ls /etc'"
result=$("$CLIENT" ls /etc 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -ne 0 ]; then
    echo "✅ Whitelist correctly rejects 'ls' command"
else
    echo "❌ Whitelist should reject 'ls' command"
fi

echo ""
echo "Test 3: Disallowed command 'git commit -m \"msg\"'"
result=$("$CLIENT" git commit -m "msg" 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -ne 0 ]; then
    echo "✅ Whitelist correctly rejects 'git' command"
else
    echo "❌ Whitelist should reject 'git' command"
fi

echo ""
echo "=== Stopping server ==="

kill "$server_pid" 2>/dev/null || true
echo "Server stopped"

echo ""
echo "=== Setup test completed ==="
echo ""
echo "To run shttp:"
echo "1. No environment variables - server will exit with error"
echo "2. Set whitelist: export SHTTP_ALLOWED_COMMANDS='echo'"
echo "3. Start server: node $SERVER"
echo "4. Run client: $CLIENT echo hello"
echo "5. Or via alias: alias echo=$CLIENT"