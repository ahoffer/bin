"""Shared library for Kubernetes CLI scripts."""

import json
import os
import re
import shutil
import subprocess
import sys
from collections import namedtuple
from typing import List, Optional, Tuple


class Colors:
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    RESET = '\033[0m'


def print_color(message: str, color: str = Colors.RESET, file=sys.stdout) -> None:
    print(f"{color}{message}{Colors.RESET}", file=file)


def print_error(message: str) -> None:
    print_color(f"ERROR: {message}", Colors.RED, file=sys.stderr)


def print_warning(message: str) -> None:
    print_color(f"WARNING: {message}", Colors.YELLOW, file=sys.stderr)


def print_success(message: str) -> None:
    print_color(message, Colors.GREEN)


def print_info(message: str) -> None:
    print_color(message, Colors.BLUE)


def die(message: str, exit_code: int = 1) -> None:
    print_error(message)
    sys.exit(exit_code)


def run_command(cmd: List[str], capture_output: bool = True,
                check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=capture_output, text=True, check=check)


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


def check_kubectl() -> None:
    if not command_exists('kubectl'):
        die("kubectl not found in PATH")
    result = run_command(['kubectl', 'cluster-info'], check=False)
    if result.returncode != 0:
        die("kubectl cannot reach the cluster")


def validate_namespace(namespace: str) -> None:
    result = run_command(['kubectl', 'get', 'namespace', namespace], check=False)
    if result.returncode != 0:
        die(f"Namespace '{namespace}' does not exist")


# ── Interactive chooser ──────────────────────────────────────────────

def choose_one(options: List[str], prompt: str = "Select") -> str:
    """Pick one item from options. Uses fzf when available, falls back to
    a numbered menu. Reads from /dev/tty so stdin pipes don't interfere.
    Auto-picks the last entry when not connected to a terminal."""
    if len(options) == 1:
        return options[0]

    if not os.path.exists('/dev/tty'):
        return options[-1]

    tty = open('/dev/tty', 'r')
    try:
        if command_exists('fzf'):
            proc = subprocess.run(
                ['fzf', '--prompt', f'{prompt} > ', '--height=40%', '--reverse'],
                input='\n'.join(options), text=True,
                stdout=subprocess.PIPE, stdin=tty,
            )
            if proc.returncode != 0 or not proc.stdout.strip():
                die("No selection made")
            return proc.stdout.strip()

        # Numbered menu fallback
        print(f"{prompt}:", file=sys.stderr)
        for i, opt in enumerate(options, 1):
            print(f"  {i}) {opt}", file=sys.stderr)
        while True:
            print(f"{prompt} [1-{len(options)}] > ", end='', file=sys.stderr, flush=True)
            line = tty.readline().strip()
            if line.isdigit() and 1 <= int(line) <= len(options):
                return options[int(line) - 1]
    finally:
        tty.close()


# ── Pod discovery ────────────────────────────────────────────────────

def find_pods(regex: str, namespace: Optional[str] = None,
              case_insensitive: bool = False) -> List[Tuple[str, str]]:
    """Find pods whose names match regex. Searches all namespaces when
    none is specified. Returns list of (namespace, pod_name) tuples
    sorted by creation time (newest last)."""
    cmd = ['kubectl', 'get', 'pods']
    if namespace:
        cmd.extend(['-n', namespace])
    else:
        cmd.append('--all-namespaces')
    cmd.extend(['--no-headers',
                '--sort-by=.metadata.creationTimestamp',
                '-o', 'custom-columns=NS:.metadata.namespace,NAME:.metadata.name'])

    result = run_command(cmd, check=False)
    if result.returncode != 0:
        die("Failed to list pods")

    flags = re.IGNORECASE if case_insensitive else 0
    matches = []
    for line in result.stdout.strip().split('\n'):
        parts = line.split()
        if len(parts) >= 2 and re.search(regex, parts[1], flags):
            matches.append((parts[0], parts[1]))
    return matches


def find_pod(regex: str, namespace: Optional[str] = None,
             case_insensitive: bool = False) -> Tuple[str, str]:
    """Find exactly one pod by regex, presenting a chooser on ambiguity.
    Returns (namespace, pod_name)."""
    matches = find_pods(regex, namespace, case_insensitive)

    if not matches:
        scope = f"in namespace {namespace}" if namespace else "in any namespace"
        die(f"No pods match: {regex} {scope}")

    if len(matches) == 1:
        return matches[0]

    labels = [f"{ns}/{pod}" for ns, pod in matches]
    chosen = choose_one(labels, "Select pod")
    ns, pod = chosen.split('/', 1)
    return (ns, pod)


def resolve_pod(regex: str, namespace: Optional[str] = None,
                case_insensitive: bool = False) -> Tuple[str, str]:
    """Check kubectl, optionally validate namespace, then resolve to exactly
    one pod. Returns (namespace, pod_name)."""
    check_kubectl()
    if namespace:
        validate_namespace(namespace)
    return find_pod(regex, namespace, case_insensitive)


# ── Container inspection ─────────────────────────────────────────────

ContainerStatus = namedtuple('ContainerStatus', ['name', 'running', 'state_description'])


def get_container_statuses(pod: str, namespace: str) -> List[ContainerStatus]:
    """Fetch container statuses for a pod via kubectl JSON output."""
    result = run_command(
        ['kubectl', '-n', namespace, 'get', 'pod', pod, '-o', 'json'],
        check=False,
    )
    if result.returncode != 0:
        die(f"Cannot get pod status for '{pod}'")

    data = json.loads(result.stdout)
    statuses = []
    for cs in data.get('status', {}).get('containerStatuses', []):
        name = cs['name']
        state = cs.get('state', {})
        if 'running' in state:
            statuses.append(ContainerStatus(name, True, f"{name}=Running"))
        elif 'waiting' in state:
            reason = state['waiting'].get('reason', 'Unknown')
            statuses.append(ContainerStatus(name, False, f"{name}=Waiting({reason})"))
        elif 'terminated' in state:
            reason = state['terminated'].get('reason', 'Unknown')
            statuses.append(ContainerStatus(name, False, f"{name}=Terminated({reason})"))
        else:
            statuses.append(ContainerStatus(name, False, f"{name}=Unknown"))
    return statuses


def resolve_container(pod: str, namespace: str,
                      container: Optional[str] = None) -> str:
    """Validate or interactively select a running container in the pod."""
    statuses = get_container_statuses(pod, namespace)
    if not statuses:
        die(f"Pod status not yet available for '{pod}'. Try again in a few seconds.")

    all_names = [s.name for s in statuses]
    running = [s.name for s in statuses if s.running]
    state_summary = ', '.join(s.state_description for s in statuses)

    if container:
        if container not in all_names:
            die(f"Container '{container}' not in pod '{pod}'. Available: {', '.join(all_names)}")
        if container not in running:
            die(f"Container '{container}' is not Running in '{pod}' (states: {state_summary}).")
        return container

    if not running:
        die(f"No Running containers in '{pod}' (states: {state_summary}).")
    if len(running) == 1:
        return running[0]

    return choose_one(running, "Select container")
