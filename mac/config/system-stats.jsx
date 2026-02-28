import { css } from "uebersicht";

export const refreshFrequency = 2000;

export const command = `
  echo "::CPU::"
  top -l 1 -n 0 | awk '/CPU usage/ {print $3, $5, $7}'
  echo "::MEM::"
  sysctl -n hw.memsize | awk '{printf "%.0f\\n", $1 / 1073741824}'
  vm_stat | awk '
    /Pages active/   {active=$3}
    /Pages wired/    {wired=$4}
    /Pages occupied by compressor/ {compressed=$6}
    /page size of/   {pagesize=$8}
    END {
      gsub(/\\./, "", active)
      gsub(/\\./, "", wired)
      gsub(/\\./, "", compressed)
      used = (active + wired + compressed) * pagesize / 1073741824
      printf "%.1f\\n", used
    }
  '
  echo "::NET::"
  route -n get default 2>/dev/null | awk '/interface:/ {print $2}' | xargs -I{} netstat -ib -I {} | awk '
    NR > 1 && $4 ~ /[0-9]/ {
      print $7, $10;
      exit
    }
  '
`;

const container = css`
  position: fixed;
  bottom: 20px;
  left: 20px;
  font-family: "SF Mono", "Menlo", monospace;
  font-size: 18px;
  color: rgba(255, 255, 255, 0.85);
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: 10px;
  padding: 14px 18px;
  line-height: 1.6;
  min-width: 234px;
`;

const label = css`
  color: rgba(255, 255, 255, 0.5);
  font-size: 15px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
`;

const row = css`
  display: flex;
  justify-content: space-between;
  align-items: baseline;
`;

const section = css`
  margin-bottom: 8px;
  &:last-child {
    margin-bottom: 0;
  }
`;

const bar = css`
  height: 3px;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 2px;
  margin-top: 3px;
  overflow: hidden;
`;

const barFill = (pct, color) => css`
  height: 100%;
  width: ${pct}%;
  background: ${color};
  border-radius: 2px;
  transition: width 0.5s ease;
`;

let prevBytes = null;
let prevTime = null;
let netRate = { down: 0, up: 0 };

function formatRate(bytesPerSec) {
  const mb = Math.min(bytesPerSec / 1048576, 999.9);
  const whole = Math.floor(mb).toString().padStart(3, "0");
  const frac = (mb % 1).toFixed(1).slice(1);
  return whole + frac + " MB/s";
}

function parse(output) {
  const sections = output.split(/::(CPU|MEM|NET)::/);
  const cpu = (sections[2] || "").trim();
  const mem = (sections[4] || "").trim();
  const net = (sections[6] || "").trim();

  const cpuParts = cpu.split(/\s+/);
  const cpuUser = parseFloat(cpuParts[0]) || 0;
  const cpuSys = parseFloat(cpuParts[1]) || 0;
  const cpuTotal = cpuUser + cpuSys;

  const memLines = mem.split(/\n/);
  const memTotal = parseFloat(memLines[0]) || 0;
  const memUsed = parseFloat(memLines[1]) || 0;
  const memPct = memTotal > 0 ? (memUsed / memTotal) * 100 : 0;

  const netParts = net.split(/\s+/);
  const bytesIn = parseInt(netParts[0]) || 0;
  const bytesOut = parseInt(netParts[1]) || 0;
  const now = Date.now();

  if (prevBytes && prevTime) {
    const dt = (now - prevTime) / 1000;
    if (dt > 0) {
      netRate = {
        down: Math.max(0, (bytesIn - prevBytes.in) / dt),
        up: Math.max(0, (bytesOut - prevBytes.out) / dt),
      };
    }
  }
  prevBytes = { in: bytesIn, out: bytesOut };
  prevTime = now;

  return { cpuTotal, memUsed, memTotal, memPct, netRate };
}

export const render = ({ output, error }) => {
  if (error) return <div className={container}>Error: {String(error)}</div>;

  const { cpuTotal, memUsed, memTotal, memPct, netRate: nr } = parse(output);

  return (
    <div className={container}>
      <div className={section}>
        <div className={row}>
          <span className={label}>cpu</span>
          <span>{cpuTotal.toFixed(0)}%</span>
        </div>
        <div className={bar}>
          <div className={barFill(cpuTotal, "#5af")} />
        </div>
      </div>
      <div className={section}>
        <div className={row}>
          <span className={label}>mem</span>
          <span>{Math.round(memUsed).toString().padStart(2, "0")} / {Math.round(memTotal).toString().padStart(2, "0")} GB</span>
        </div>
        <div className={bar}>
          <div className={barFill(memPct, "#fa5")} />
        </div>
      </div>
      <div className={section}>
        <div className={row}>
          <span className={label}>down</span>
          <span>{formatRate(nr.down)}</span>
        </div>
        <div className={row}>
          <span className={label}>up</span>
          <span>{formatRate(nr.up)}</span>
        </div>
      </div>
    </div>
  );
};
