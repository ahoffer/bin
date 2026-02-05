#!/usr/bin/env python3
"""
Kubernetes Utilities Library
Common functions for Kubernetes operations and general utilities.
"""

import argparse
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple, Union


class Colors:
    """ANSI color codes for terminal output."""
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    RESET = '\033[0m'


def print_color(message: str, color: str = Colors.RESET, file=sys.stdout) -> None:
    """Print a colored message to the specified file."""
    print(f"{color}{message}{Colors.RESET}", file=file)


def print_error(message: str) -> None:
    """Print an error message in red to stderr."""
    print_color(f"ERROR: {message}", Colors.RED, file=sys.stderr)


def print_warning(message: str) -> None:
    """Print a warning message in yellow to stderr."""
    print_color(f"WARNING: {message}", Colors.YELLOW, file=sys.stderr)


def print_success(message: str) -> None:
    """Print a success message in green."""
    print_color(message, Colors.GREEN)


def print_info(message: str) -> None:
    """Print an info message in blue."""
    print_color(message, Colors.BLUE)


def die(message: str, exit_code: int = 1) -> None:
    """Print an error message and exit."""
    print_error(message)
    sys.exit(exit_code)


def run_command(cmd: List[str], capture_output: bool = True, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=capture_output,
            text=True,
            check=check
        )
        return result
    except subprocess.CalledProcessError as e:
        if check:
            raise
        return e


def command_exists(command: str) -> bool:
    """Check if a command exists in PATH."""
    return shutil.which(command) is not None


def check_kubectl() -> None:
    """Check if kubectl is available and can connect to cluster."""
    if not command_exists('kubectl'):
        die("kubectl not found in PATH")
    
    result = run_command(['kubectl', 'cluster-info'], check=False)
    if result.returncode != 0:
        die("kubectl cannot reach the cluster")


def validate_namespace(namespace: str) -> None:
    """Validate that a namespace exists."""
    result = run_command(['kubectl', 'get', 'namespace', namespace], check=False)
    if result.returncode != 0:
        die(f"Namespace '{namespace}' does not exist")


def find_pod(regex: str, namespace: Optional[str] = None) -> str:
    """Find a single pod by regex pattern."""
    cmd = ['kubectl']
    if namespace:
        cmd.extend(['-n', namespace])
    cmd.extend(['get', 'pods', '-o', 'name'])
    
    result = run_command(cmd)
    if result.returncode != 0:
        die("Failed to list pods")
    
    # Strip "pod/" prefix and filter by regex
    pod_names = []
    for line in result.stdout.strip().split('\n'):
        if line:
            pod_name = line.replace('pod/', '')
            if re.search(regex, pod_name):
                pod_names.append(pod_name)
    
    if not pod_names:
        die(f"No pods match: {regex}")
    elif len(pod_names) > 1:
        print_error(f"More than one pod matches: {regex}")
        for pod in pod_names:
            print(f"  {pod}", file=sys.stderr)
        sys.exit(1)
    
    return pod_names[0]


def find_pods(regex: str, namespace: Optional[str] = None) -> List[str]:
    """Find multiple pods by regex pattern."""
    cmd = ['kubectl']
    if namespace:
        cmd.extend(['-n', namespace])
    cmd.extend(['get', 'pods', '-o', 'name'])
    
    result = run_command(cmd)
    if result.returncode != 0:
        die("Failed to list pods")
    
    # Strip "pod/" prefix and filter by regex
    pod_names = []
    for line in result.stdout.strip().split('\n'):
        if line:
            pod_name = line.replace('pod/', '')
            if re.search(regex, pod_name):
                pod_names.append(pod_name)
    
    return pod_names


def resolve_pod(regex: str, namespace: Optional[str] = None) -> str:
    """Check kubectl, optionally validate namespace, then resolve to exactly one pod."""
    check_kubectl()
    if namespace:
        validate_namespace(namespace)
    return find_pod(regex, namespace)


def get_script_dir() -> Path:
    """Get the directory of the current script."""
    return Path(__file__).parent.absolute()


def confirm(message: str = "Proceed?") -> bool:
    """Ask user for confirmation."""
    try:
        response = input(f"{message} (y/N): ").strip().lower()
        return response in ('y', 'yes')
    except (EOFError, KeyboardInterrupt):
        return False


def is_valid_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    return bool(re.match(pattern, email))


def is_valid_url(url: str) -> bool:
    """Validate URL format."""
    pattern = r'^https?://[A-Za-z0-9._~:/?#\[\]@!$()*+,=%-]+$'
    return bool(re.match(pattern, url))


def is_valid_ipv4(ip: str) -> bool:
    """Validate IPv4 address."""
    pattern = r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    return bool(re.match(pattern, ip))


def get_os_type() -> str:
    """Get OS type."""
    import platform
    system = platform.system().lower()
    if system == 'linux':
        return 'linux'
    elif system == 'darwin':
        return 'darwin'
    else:
        return 'unknown'


def is_linux() -> bool:
    """Check if running on Linux."""
    return get_os_type() == 'linux'


def is_macos() -> bool:
    """Check if running on macOS."""
    return get_os_type() == 'darwin'


def get_arch() -> str:
    """Get CPU architecture."""
    import platform
    return platform.machine()


def port_in_use(port: int) -> bool:
    """Check if port is in use."""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(('localhost', port))
            return False
        except OSError:
            return True


def get_local_ip() -> Optional[str]:
    """Get local IP address."""
    import socket
    try:
        # Connect to a remote address to determine local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(('8.8.8.8', 80))
            return s.getsockname()[0]
    except OSError:
        return None


def check_docker() -> None:
    """Check if Docker is available."""
    if not command_exists('docker'):
        die("docker not found in PATH")
    
    result = run_command(['docker', 'info'], check=False)
    if result.returncode != 0:
        die("docker is not running or not accessible")


def get_docker_container(pattern: str) -> str:
    """Get Docker container ID by name pattern."""
    cmd = ['docker', 'ps', '--filter', f'name={pattern}', '--format', '{{.ID}}']
    result = run_command(cmd)
    
    container_ids = result.stdout.strip().split('\n')
    if not container_ids or not container_ids[0]:
        die(f"No container matches: {pattern}")
    
    return container_ids[0]


def is_git_repo() -> bool:
    """Check if current directory is a git repository."""
    result = run_command(['git', 'rev-parse', '--git-dir'], check=False)
    return result.returncode == 0


def get_git_branch() -> Optional[str]:
    """Get current git branch."""
    if not is_git_repo():
        print_error("Not a git repository")
        return None
    
    result = run_command(['git', 'branch', '--show-current'])
    return result.stdout.strip()


def is_git_clean() -> bool:
    """Check if git working directory is clean."""
    if not is_git_repo():
        print_error("Not a git repository")
        return False
    
    result = run_command(['git', 'diff-index', '--quiet', 'HEAD', '--'], check=False)
    return result.returncode == 0


def process_running(pattern: str) -> bool:
    """Check if process is running."""
    if is_linux():
        result = run_command(['pgrep', '-f', pattern], check=False)
        return result.returncode == 0
    else:
        # Fallback for other OS
        result = run_command(['ps', 'aux'], check=False)
        return pattern in result.stdout


def kill_process(pattern: str) -> bool:
    """Kill process by name pattern."""
    if is_linux():
        result = run_command(['pgrep', '-f', pattern], check=False)
        if result.returncode != 0:
            print_warning(f"No processes found matching: {pattern}")
            return False
        
        pids = result.stdout.strip().split('\n')
        if pids:
            run_command(['kill'] + pids)
            print_success(f"Killed processes: {' '.join(pids)}")
            return True
    return False


# Import shutil for command_exists function
import shutil
