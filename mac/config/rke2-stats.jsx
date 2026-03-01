import { css } from "uebersicht";

export const refreshFrequency = 3000;

export const command = String.raw`
  LIST_LINE=$(limactl list 2>/dev/null | awk '$1=="rke2" {print $0}')

  if [ -z "$LIST_LINE" ]; then
    printf 'status=missing\n'
    printf 'cpu=0.0\n'
    printf 'mem_gb=0.00\n'
    printf 'configured_cpus=0\n'
    printf 'configured_mem=0\n'
    exit 0
  fi

  STATUS=$(printf '%s\n' "$LIST_LINE" | awk '{print $2}')
  CONFIGURED_CPUS=$(printf '%s\n' "$LIST_LINE" | awk '{print $4}')
  CONFIGURED_MEM=$(printf '%s\n' "$LIST_LINE" | awk '{print $5}')

  HOST_PID=$(ps -axo pid=,command= | awk '
    /limactl hostagent/ && /\/\.lima\/rke2\/ha\.pid/ {
      print $1
      exit
    }
  ')

  CPU=0.0
  RSS_KB=0

  if [ -n "$HOST_PID" ]; then
    DESCENDANTS=$(ps -axo pid=,ppid=,pcpu=,rss= | awk -v root="$HOST_PID" '
      function add(pid) {
        if (!(pid in keep)) {
          keep[pid] = 1
          changed = 1
        }
      }

      {
        pid = $1
        parent[pid] = $2
        cpu[pid] = $3
        rss[pid] = $4
        if (pid == root) {
          keep[pid] = 1
        }
      }

      END {
        do {
          changed = 0
          for (pid in parent) {
            if ((parent[pid] in keep) && !(pid in keep)) {
              add(pid)
            }
          }
        } while (changed)

        for (pid in keep) {
          print cpu[pid], rss[pid]
        }
      }
    ')

    if [ -n "$DESCENDANTS" ]; then
      CPU=$(printf '%s\n' "$DESCENDANTS" | awk '{sum += $1} END {printf "%.1f", sum + 0}')
      RSS_KB=$(printf '%s\n' "$DESCENDANTS" | awk '{sum += $2} END {printf "%.0f", sum + 0}')
    fi
  fi

  MEM_GB=$(awk -v kb="$RSS_KB" 'BEGIN {printf "%.2f", kb / 1048576}')

  printf 'status=%s\n' "$STATUS"
  printf 'cpu=%s\n' "$CPU"
  printf 'mem_gb=%s\n' "$MEM_GB"
  printf 'configured_cpus=%s\n' "$CONFIGURED_CPUS"
  printf 'configured_mem=%s\n' "$CONFIGURED_MEM"
`;

const container = css`
  position: fixed;
  bottom: 20px;
  left: 280px;
  min-width: 260px;
  padding: 14px 16px;
  border-radius: 12px;
  background: rgba(14, 19, 24, 0.78);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  color: rgba(244, 247, 250, 0.94);
  font-family: "SF Mono", "Menlo", monospace;
  box-shadow: 0 14px 36px rgba(0, 0, 0, 0.24);
`;

const header = css`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 14px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
`;

const title = css`
  color: rgba(244, 247, 250, 0.72);
`;

const statusBadge = (running) => css`
  padding: 3px 8px;
  border-radius: 999px;
  font-size: 12px;
  color: ${running ? "#c8ffd6" : "#ffd6d6"};
  background: ${running ? "rgba(40, 167, 69, 0.2)" : "rgba(220, 53, 69, 0.2)"};
`;

const metric = css`
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 6px;
  font-size: 17px;
`;

const label = css`
  color: rgba(244, 247, 250, 0.58);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
`;

const footer = css`
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid rgba(244, 247, 250, 0.1);
  font-size: 12px;
  color: rgba(244, 247, 250, 0.5);
`;

function parseOutput(output) {
  return output
    .trim()
    .split("\n")
    .reduce((acc, line) => {
      const [key, ...rest] = line.split("=");
      acc[key] = rest.join("=");
      return acc;
    }, {});
}

export const render = ({ output, error }) => {
  if (error) {
    return <div className={container}>rke2 widget error: {String(error)}</div>;
  }

  const data = parseOutput(output);
  const status = data.status || "missing";
  const running = status === "Running";
  const cpu = Number.parseFloat(data.cpu || "0");
  const memGb = Number.parseFloat(data.mem_gb || "0");
  const configuredCpus = data.configured_cpus || "0";
  const configuredMem = data.configured_mem || "0";

  return (
    <div className={container}>
      <div className={header}>
        <span className={title}>rke2</span>
        <span className={statusBadge(running)}>{status.toLowerCase()}</span>
      </div>
      <div className={metric}>
        <span className={label}>Host CPU</span>
        <span>{cpu.toFixed(1)}%</span>
      </div>
      <div className={metric}>
        <span className={label}>Host RSS</span>
        <span>{memGb.toFixed(2)} GB</span>
      </div>
      <div className={footer}>
        alloc: {configuredCpus} vCPU / {configuredMem}
      </div>
    </div>
  );
};
