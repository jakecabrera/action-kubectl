#!/bin/sh

set -e  # Exit script immediately if a command fails
set -o pipefail  # Fail the script if any command in a pipeline fails

# Logging functions for different levels of messages
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1" >&2
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

log "Starting GitHub Action entrypoint..."

# Ensure .kube directory exists for Kubernetes configuration
KUBE_DIR="$HOME/.kube"
if [ ! -d "$KUBE_DIR" ]; then
    log "Creating kube config directory at $KUBE_DIR"
    mkdir -p "$KUBE_DIR"
fi

KUBE_CONFIG_FILE="$KUBE_DIR/config"

# Retrieve input values or fall back to environment variables
KUBE_HOST="${INPUT_KUBE_HOST:-$KUBE_HOST}"
KUBE_CERTIFICATE="${INPUT_KUBE_CERTIFICATE:-$KUBE_CERTIFICATE}"
KUBE_USERNAME="${INPUT_KUBE_USERNAME:-$KUBE_USERNAME}"
KUBE_PASSWORD="${INPUT_KUBE_PASSWORD:-$KUBE_PASSWORD}"
KUBE_TOKEN="${INPUT_KUBE_TOKEN:-$KUBE_TOKEN}"
KUBE_CONFIG="${INPUT_KUBE_CONFIG:-$KUBE_CONFIG}"

# Normalize boolean inputs to lowercase for consistent handling
INPUT_DISPLAY_COMMAND="$(echo "$INPUT_DISPLAY_COMMAND" | tr '[:upper:]' '[:lower:]')"
INPUT_DISPLAY_RESULTS="$(echo "$INPUT_DISPLAY_RESULTS" | tr '[:upper:]' '[:lower:]')"

# Configure Kubernetes authentication
if [ ! -f "$KUBE_CONFIG_FILE" ]; then
    if [ -n "$KUBE_CONFIG" ]; then
        log "Decoding and setting KUBE_CONFIG"
        echo "$KUBE_CONFIG" | base64 -d > "$KUBE_CONFIG_FILE"
    elif [ -n "$KUBE_HOST" ]; then
        log "Setting Kubernetes cluster details via KUBE_HOST"
        echo "$KUBE_CERTIFICATE" | base64 -d > "$KUBE_DIR/certificate"
        kubectl config set-cluster default --server="https://$KUBE_HOST" --certificate-authority="$KUBE_DIR/certificate" > /dev/null

        # Set authentication method
        if [ -n "$KUBE_PASSWORD" ]; then
            log "Setting cluster-admin credentials via username/password"
            kubectl config set-credentials cluster-admin --username="$KUBE_USERNAME" --password="$KUBE_PASSWORD" > /dev/null
        elif [ -n "$KUBE_TOKEN" ]; then
            log "Setting cluster-admin credentials via token"
            kubectl config set-credentials cluster-admin --token="$KUBE_TOKEN" > /dev/null
        else
            error "No credentials found. Please provide KUBE_TOKEN, or KUBE_USERNAME and KUBE_PASSWORD."
        fi

        kubectl config set-context default --cluster=default --namespace=default --user=cluster-admin > /dev/null
        kubectl config use-context default > /dev/null
    else
        error "No authorization data found. Please provide KUBE_CONFIG or KUBE_HOST variables."
    fi
fi

# Display the command being executed if enabled
if [ "$INPUT_DISPLAY_COMMAND" = "true" ]; then
    log "Executing command: kubectl $INPUT_ARGS"
else
    log "Command display is suppressed."
fi

# Execute the kubectl command and trim leading/trailing spaces and newlines from output
RESULT=$(kubectl $INPUT_ARGS 2>&1 | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Display command output if enabled
if [ "$INPUT_DISPLAY_RESULTS" = "true" ]; then
    echo "$RESULT"
else
    log "Output display is suppressed."
fi

# If an output variable is specified, store the command output there
if [ -n "$INPUT_OUTPUT_VARIABLE" ]; then
    log "Redirecting output to environment variable $INPUT_OUTPUT_VARIABLE"
    EOF_MARKER=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)
    echo "$INPUT_OUTPUT_VARIABLE<<$EOF_MARKER" >> "$GITHUB_ENV"
    echo "$RESULT" >> "$GITHUB_ENV"
    echo "$EOF_MARKER" >> "$GITHUB_ENV"
    echo "::add-mask::$INPUT_OUTPUT_VARIABLE"
fi

log "GitHub Action completed successfully."
