# shttp - HTTP Proxy Server for Whitelisted Commands

**shttp** is a lightweight HTTP proxy server that allows executing whitelisted commands from the PATH (or any configured path) through HTTP. It’s built in Node.js and designed for safe, sandboxed command execution over the network.

## Overview

- **Protocol**: HTTP
- **Methods**:
  - `GET /bash` – Returns a Bash script with generated functions for each allowed command.
  - `POST /` – Executes a command and returns its stdout, stderr, and exit code.
- **Environment Variables**:
  - `SHTTP_ENDPOINT` – Server endpoint URL, including port (default: `http://localhost:8080`). Note: `SHTTP_PORT` is no longer supported; use `SHTTP_ENDPOINT` to specify both host and port.
  - `SHTTP_ALLOWED_COMMANDS` – Whitelist of commands (space‑ or comma‑separated, e.g. `"git curl wget python"`)
- **Body format for POST /**: First line = JSON array of arguments, remaining bytes = stdin data.

## Installation

Assuming you have Node.js installed:

```bash
# Clone this repo (if applicable) or place the `shttp` script in your project.
# Install the only dependency (`debug`).
npm install
# Make the executable script runnable (if needed).
chmod +x shttp
```

> **Note**: The `shttp` script is a Node.js program that uses the standard `#!/usr/bin/env node` shebang, so you can invoke it directly on Unix‑like systems.

## Quick start

### 1. Start the server

```bash
# Example: allow only `git`, `curl`, and `python3`
SHTTP_ALLOWED_COMMANDS="git curl python3" ./shttp
```

The server will output debug messages (on the console) showing the endpoint, whitelist, and ready state.

### 2. Generate a client script

Open another terminal and request the Bash helper script:

```bash
curl -s http://localhost:8080/bash > shttp-client.sh
```

Make it executable and source it (or directly embed the generated functions):

```bash
chmod +x shttp-client.sh
source shttp-client.sh
```

You should now have interactive Bash functions such as:

```bash
git() { shttp_client 'git' "$@"; }
curl() { shttp_client 'curl' "$@"; }
python() { shttp_client 'python' "$@"; }
```

### 3. Run a command

Now you can call the allowed commands as if they were locally installed:

```bash
git --version
curl -I https://example.com
python -c "print('Hello from shttp!')"
```

Behind the scenes, each call:
1. Builds a JSON argument array, e.g. `["git","--version"]`.
2. Sends it as the first line of a POST request to `http://localhost:8080/` (or `${SHTTP_ENDPOINT}`). The remaining request body is any stdin data you’d like to feed (often empty).
3. Receives the command’s stdout, stderr (base‑64 encoded), exit code, and any special flags (`X-SHTTP-Timeout`, `X-SHTTP-Output-Limit`, etc.) in the HTTP headers.
4. Returns the stdout directly to your terminal, reproducing the command’s normal output.

## Detailed usage

### 3.1. Direct HTTP interaction

If you prefer not to use the generated Bash script, you can talk to the server directly with `curl`. Remember that the body must start with a JSON array of arguments, and the rest is the stdin payload.

**Example – run `git log --oneline -5` with empty stdin:**

```bash
cat <<'EOF' | curl -X POST http://localhost:8080/ -d @-
["git","log","--oneline","-5"]
EOF
```

**Example – feed a script to `python`:**

```bash
SCRIPT='print("Hello world")'
PAYLOAD=$(printf '["python"]\n%s' "$SCRIPT")
printf "%s" "$PAYLOAD" | curl -X POST http://localhost:8080/ -d @-
```

**Example – capture errors:**

The server returns a `X-SHTTP-Stderr` header with base‑64 encoded stderr (truncated to 4 KB). If the command fails, the exit code is reflected in the `X-SHTTP-Exit-Code` header (e.g., `curl -w "%{x-shttp-exit-code}" ...`).

### 3.2. Configuration

- **Whitelist format**: any space or comma separated list. Invalid commands are silently ignored.
- **Timeout**: commands are forcibly killed after 30 seconds (configurable via the code). The exit code becomes `1`.
- **Output size limit**: maximum 5 MiB of combined stdout + stderr; exceeding this aborts the command.
- **Body size limit**: maximum 10 MiB of request body; larger bodies are rejected with 413.

### 3.3. Security considerations

- Only commands listed in `SHTTP_ALLOWED_COMMANDS` are executable.
- No additional environment variables or PATH manipulation is exposed to the child process beyond the current environment (the child inherits `process.env` but the whitelist check prevents arbitrary binaries).
- The server does not grant shell access; commands are executed directly via `spawn` with `shell: false`.
- All stderr is base‑64 encoded in headers to keep the HTTP body strictly binary‑safe.

## Project structure

```text
/home/bashbot/shttp
├── .git/                     # Git metadata
├── .gitignore
├── package.json            # Dependency and metadata
├── package-lock.json
├── node_modules/           # Installed packages (`debug`)
├── shttp                    # Executable Node.js server script
└── server.log              # Debug log from the server (if enabled)
```

## See also

- [Node.js `child_process.spawn` documentation](https://nodejs.org/api/child_process.html#child_proces_spawn)
- [`debug` module](https://github.com/debug-js/debug) – logging utility used internally.

## License

(Insert your preferred license here. For example, MIT.)

## Feedback & Contributions

Feel free to open issues or pull‑requests in the repository. Improvements to the whitelist logic, timeout handling, or additional client‑side helpers are always welcome.