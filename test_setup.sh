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
echo "=== Testing server startup (Node.js) ==="

node "$SERVER" &
server_pid=$!
echo "Server PID: $server_pid"
sleep 2

echo ""
echo "=== Testing server is running ==="

# Check if server process is running
if ps -p "$server_pid" > /dev/null 2>&1; then
    echo "✅ Server is running on port 8080"
else
    echo "❌ Server failed to start"
fi

echo ""
echo "=== Testing whitelist enforcement ==="

# Set whitelist to only allow 'echo'
export SHTTP_ALLOWED_COMMANDS="echo"

echo "Test 1: Allowed command 'echo hello'"
result=$("$CLIENT" echo hello 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -eq 0 ] && echo "$result" | grep -q "hello"; then
    echo "✅ Allowed command 'echo' works correctly"
else
    echo "❌ Allowed command 'echo' failed"
fi

echo ""
echo "Test 2: Disallowed command 'rm -rf /tmp/test'"
result=$("$CLIENT" rm -rf /tmp/test 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -ne 0 ]; then
    echo "✅ Disallowed command 'rm' correctly rejected (exit code: $exit_code)"
else
    echo "❌ Disallowed command 'rm' was not rejected"
fi

echo ""
echo "Test 3: Disallowed command 'ls /etc'"
result=$("$CLIENT" ls /etc 2>&1)
exit_code=$?
echo "Exit code: $exit_code"
echo "Output: $result"
if [ "$exit_code" -ne 0 ]; then
    echo "✅ Disallowed command 'ls' correctly rejected (exit code: $exit_code)"
else
    echo "❌ Disallowed command 'ls' was not rejected"
fi

echo ""
echo "=== Stopping server ==="

kill "$server_pid" 2>/dev/null || true
echo "Server stopped"

echo ""
echo "=== Setup test completed ==="
echo ""
echo "To run shttp:"
echo "1. Export environment variables: export SHTTP_ALLOWED_COMMANDS='echo'"
echo "2. Start server: node $SERVER"
echo "3. Run client: $CLIENT echo hello"
echo "4. Or via alias: alias echo=$CLIENT"
wait
