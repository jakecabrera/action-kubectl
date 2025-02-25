import os
import shlex
import subprocess
import sys
import base64
import secrets

def log(message):
    print(f"[INFO] {message}")

def warn(message):
    print(f"[WARN] {message}")

def error(message):
    print(f"[ERROR] {message}")
    sys.exit(1)

def expand_env_variables(command):
    """Expands environment variables within a command string."""
    return os.path.expandvars(command)

def main():
    log("Starting GitHub Action entrypoint...")
    
    # Retrieve inputs from environment variables
    kube_config = os.getenv("INPUT_KUBE_CONFIG") or os.getenv("KUBE_CONFIG")
    kube_host = os.getenv("INPUT_KUBE_HOST") or os.getenv("KUBE_HOST")
    kube_certificate = os.getenv("INPUT_KUBE_CERTIFICATE") or os.getenv("KUBE_CERTIFICATE")
    kube_username = os.getenv("INPUT_KUBE_USERNAME") or os.getenv("KUBE_USERNAME")
    kube_password = os.getenv("INPUT_KUBE_PASSWORD") or os.getenv("KUBE_PASSWORD")
    kube_token = os.getenv("INPUT_KUBE_TOKEN") or os.getenv("KUBE_TOKEN")
    args = os.getenv("INPUT_ARGS", "")
    output_variable = os.getenv("INPUT_OUTPUT_VARIABLE")
    display_results = os.getenv("INPUT_DISPLAY_RESULTS", "true").lower() == "true"
    display_command = os.getenv("INPUT_DISPLAY_COMMAND", "true").lower() == "true"

    # Ensure .kube directory exists
    kube_dir = os.path.expanduser("~/.kube")
    os.makedirs(kube_dir, exist_ok=True)
    kube_config_path = os.path.join(kube_dir, "config")
    
    # Handle authentication
    if kube_config:
        log("Decoding and setting kubeconfig file")
        try:
            decoded_config = base64.b64decode(kube_config).decode("utf-8")
        except Exception as e:
            error(f"Failed to decode kubeconfig: {e}")
        with open(kube_config_path, "w") as f:
            f.write(decoded_config)
        os.environ["KUBECONFIG"] = kube_config_path
    elif kube_host:
        log("Configuring Kubernetes authentication using host credentials")
        with open(os.path.join(kube_dir, "certificate"), "w") as f:
            f.write(kube_certificate or "")
        
        subprocess.run(["kubectl", "config", "set-cluster", "default", \
                        "--server=https://" + kube_host, \
                        "--certificate-authority=" + os.path.join(kube_dir, "certificate")], check=True)
        
        if kube_username and kube_password:
            subprocess.run(["kubectl", "config", "set-credentials", "cluster-admin", \
                            "--username=" + kube_username, "--password=" + kube_password], check=True)
        elif kube_token:
            subprocess.run(["kubectl", "config", "set-credentials", "cluster-admin", \
                            "--token=" + kube_token], check=True)
        else:
            error("No credentials found. Please provide KUBE_TOKEN, or KUBE_USERNAME and KUBE_PASSWORD")
        
        subprocess.run(["kubectl", "config", "set-context", "default", "--cluster=default", \
                        "--namespace=default", "--user=cluster-admin"], check=True)
        subprocess.run(["kubectl", "config", "use-context", "default"], check=True)
    else:
        error("No authorization data found. Please provide KUBE_CONFIG or KUBE_HOST variables")
    
    # Expand environment variables in args
    expanded_args = expand_env_variables(args)
    command_list = shlex.split(expanded_args)
    
    if display_command:
        log(f"Executing command: kubectl {' '.join(command_list)}")
    else:
        log("Command display is suppressed")
    
    # Execute the kubectl command
    try:
        result = subprocess.run(["kubectl"] + command_list, capture_output=True, text=True, check=True)
        output = result.stdout
    except subprocess.CalledProcessError as e:
        error(f"Command failed: {e.stderr}")
    
    # Display or store output
    if display_results:
        log("Command output:")
        print(output)
        log("End of command output")
    else:
        log("Output display is suppressed")
    
    if output_variable:
        log(f"Storing output in environment variable: {output_variable}")
        env_file_path = os.getenv("GITHUB_ENV", "")
        if env_file_path:
            eof_marker = secrets.token_hex(15)  # Generate a random EOF marker
            # Remove leading/trailing empty lines
            lines = output.splitlines()
            while lines and not lines[0].strip():
                lines.pop(0)
            while lines and not lines[-1].strip():
                lines.pop()
            output = "\n".join(lines)

            with open(env_file_path, "a") as env_file:
                env_file.write(f"{output_variable}<<{eof_marker}\n")
                env_file.write(output + "\n")
                env_file.write(f"{eof_marker}\n")
        else:
            warn("GITHUB_ENV environment variable not set. Cannot store output")
    
    log("GitHub Action completed successfully")

if __name__ == "__main__":
    main()
