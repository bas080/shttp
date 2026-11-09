# shttp

A lightweight HTTP proxy server that allows running commands from the PATH (or any configured path) through HTTP. It acts as a simple bridge between the client and a configured server, proxying arguments via a single JSON body to the target command.

## Features

- **Command Proxying**: Run any command from the PATH (or custom path) via HTTP.
- **Simple Bash Utility**: A CLI tool named `shttp` (written in sh) that uses `curl` to forward arguments and stdin to the configured server. The `shttp` utility exits with the same exit code as the command that ran and outputs stdout only.
- **Whitelist Configuration**: Control which commands are allowed via an environment variable (`SHTTP_ALLOWED_COMMANDS`).
- **HTTP Interface**: The server exposes a simple HTTP endpoint for command execution.
- **Aliases**: Define shell aliases to quickly proxy specific commands via HTTP.

## Quick Start

### 1. Configure Whitelisted Commands

Set the `SHTTP_ALLOWED_COMMANDS` environment variable to a whitelist of commands that the proxy will allow:

```bash
export SHTTP_ALLOWED_COMMANDS="git curl wget python"
```

Only commands listed in `SHTTP_ALLOWED_COMMANDS` will be permitted.

### 2. Start the Server

```bash
shttp
```

The server listens on port `SHTTP_PORT` (default: 8080). It expects a POST request with a raw string body like `git commit -m "Initial commit"`. It streams only **stdout** back; stderr is ignored in this version. Exit codes are returned to the client.

> **Note**: For the **first version**, stdin support is deferred. The server accepts a raw string body like `git commit -m "Initial commit"` and streams **stdout** back. Exit codes are propagated back to the client correctly via `__EXIT_CODE__:N` marker.

> **Note**: Standard error is not captured/streamed in the first version. Only standard output and the exit code are handled.

### 3. Run a Command

Send a POST request with a raw string body:

```bash
curl -X POST http://localhost:8080/ -H "Content-Type: text/plain" -d 'git commit -m "Initial commit"'
```

## How It Works

1. The `shttp` server listens on a configurable port (default: 8080).
2. When a POST request is received with a raw string body like `git commit -m "Initial commit"`, the server splits it into the command and arguments.
3. If the command is in the `SHTTP_ALLOWED_COMMANDS` whitelist, it is executed with the remaining arguments.
4. The server streams **stdout** back to the client via HTTP response, and returns the command's exit code.

## Configuration

All environment variables use the `SHTTP_` prefix (matching the project name):

### Allowed Commands

The `SHTTP_ALLOWED_COMMANDS` environment variable defines a whitelist of commands that can be executed. Each command must be found on the system PATH.

Example:
```bash
export SHTTP_ALLOWED_COMMANDS="git curl wget python"
```

### Server Port

Change the port by setting the `SHTTP_PORT` environment variable:
```bash
export SHTTP_PORT=9000
shttp
```

### Wrapper URL (rapper)

Change the server URL by setting the `SHTTP_WRAPPER_URL` environment variable (default: `http://localhost:8080`):
```bash
export SHTTP_WRAPPER_URL="http://localhost:9000"
shttp git commit -m "msg"
```


## Aliases

You can define shell aliases to quickly proxy specific commands via HTTP. For example, to proxy `git`:

```bash
alias git='shttp git'
```

Now you can run `git commit -m "msg"` to proxy `git commit` through the server.

## Usage Examples

| Example | Description |
|---------|-------------|
| ```bash
curl -X POST http://localhost:8080/ -H "Content-Type: text/plain" -d 'git commit -m "msg"'
``` | Execute `git commit` via the proxy |
| ```bash
curl -X POST http://localhost:8080/ -H "Content-Type: text/plain" -d 'wget https://example.com/file.zip'
``` | Execute `wget` to download a file |
| ```bash
curl -X POST http://localhost:8080/ -H "Content-Type: text/plain" -d 'python -c "print(\"hello\")"'
``` | Run a Python one-liner |
| ```bash
curl -X POST http://localhost:8080/ -H "Content-Type: text/plain" -d 'unknowncmd arg'
``` | Attempt to run an unauthorized command (will be rejected) |
| ```bash
shttp git commit -m "msg"
``` | Execute `git commit` via the shttp wrapper utility |

## Security Notes

- Only commands listed in `SHTTP_ALLOWED_COMMANDS` are permitted.
- The server does not validate command arguments beyond the whitelist.
- Be cautious when using this proxy with untrusted inputs.
- The server runs commands in the current shell context; ensure the whitelist is comprehensive.

## Development

### Building

The server is a simple script; ensure it is executable:

```bash
chmod +x shttp
```

### Running Tests

```bash
# If you add tests, run them with the appropriate test runner
```

## License

MIT