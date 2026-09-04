import QtQuick
import Quickshell.Io

// Samples CPU / memory / GPU / disk usage while its owner (the system widget)
// exists. Sensor paths and the GPU backend are probed once at start with a
// small shell script; the sampler prints one line per metric and the parser
// fills the properties below.
//
// One `sh` per tick is the whole cost. Disks are the expensive part (`df`
// stats every mount), so they are only refreshed every `diskEvery` ticks, or
// immediately when `detailed` flips on because the panel opened.
QtObject {
  id: root

  property int interval: 2000
  property int diskEvery: 15
  // Set by the panel while it is open; forces a disk refresh on the next tick.
  property bool detailed: false

  property real cpu: 0            // total busy %
  property int cpuTemp: -1        // °C, -1 when unknown
  property real memPercent: 0
  property real memUsedGiB: 0
  property real memTotalGiB: 0
  property real swapPercent: 0
  property real swapUsedGiB: 0
  property real swapTotalGiB: 0
  property bool gpuAvailable: false
  property real gpuUtil: 0
  property int gpuTemp: -1
  property real gpuMemUsedGiB: 0
  property real gpuMemTotalGiB: 0
  property var disks: []          // [{ device, mount, usedGiB, totalGiB, percent, temp }]
  property var topCpu: []         // [{ name, value }] value = %CPU, sampled only while detailed
  property var topMem: []         // [{ name, value }] value = MiB
  property bool btopAvailable: false
  property int topCount: 5

  property string tempPath: ""
  property string gpuKind: "none" // nvidia | amd | none
  property string gpuBusyPath: ""
  property string gpuTempPath: ""
  // "nvme0=/sys/class/hwmon/hwmonN/temp1_input nvme1=…", matched against the
  // disk device name so each NVMe row can show its composite temperature.
  property string diskTempMap: ""
  property real prevTotal: -1
  property real prevIdle: -1
  property int tick: 0
  property bool disksPending: true

  readonly property string probeScript: `
    t=""
    dt=""
    for h in /sys/class/hwmon/hwmon*; do
      case "$(cat "$h/name" 2>/dev/null)" in
        coretemp|k10temp|zenpower) [ -z "$t" ] && [ -r "$h/temp1_input" ] && t="$h/temp1_input" ;;
        nvme) [ -r "$h/temp1_input" ] && dt="$dt $(basename "$(readlink -f "$h/device")")=$h/temp1_input" ;;
      esac
    done
    echo "temp $t"
    echo "disktemp$dt"
    if command -v nvidia-smi >/dev/null 2>&1; then echo "gpu nvidia"
    else
      for c in /sys/class/drm/card*/device; do
        [ -r "$c/gpu_busy_percent" ] || continue
        gt=""
        for h in "$c"/hwmon/hwmon*; do [ -r "$h/temp1_input" ] && { gt="$h/temp1_input"; break; }; done
        echo "gpu amd $c/gpu_busy_percent $gt"
        break
      done
    fi
    command -v btop >/dev/null 2>&1 && echo "btop 1" || echo "btop 0"
  `

  // $1 temp path, $2 gpu kind, $3 gpu busy path, $4 gpu temp path,
  // $5 "1" to include disks, $6 disk temp map, $7 "1" to include the
  // process tables (the panel is open), $8 how many rows of each.
  readonly property string sampleScript: `
    read -r _ u n s i w q sq st _ < /proc/stat
    echo "cpu $u $n $s $i $w $q $sq $st"
    [ -n "$1" ] && echo "temp $(cat "$1" 2>/dev/null)"
    awk '/^(MemTotal|MemAvailable|SwapTotal|SwapFree):/ { v[$1] = $2 }
         END { print "mem", v["MemTotal:"], v["MemAvailable:"], v["SwapTotal:"], v["SwapFree:"] }' /proc/meminfo
    case "$2" in
      nvidia) nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d " " | tr "," " " | sed "s/^/gpu /" ;;
      amd) t=$(cat "$4" 2>/dev/null || echo -1000); echo "gpu $(cat "$3" 2>/dev/null) $((t / 1000)) 0 0" ;;
    esac
    if [ "$5" = 1 ]; then
      df -P -B1 / /home 2>/dev/null | awk 'NR > 1 && !seen[$1]++ { print "disk", $1, $6, $3, $2 }'
      for pair in $6; do
        echo "dtemp \${pair%%=*} $(cat "\${pair#*=}" 2>/dev/null)"
      done
    fi
    if [ "$7" = 1 ]; then
      # top's first frame is a lifetime average; the second, 0.4s later,
      # is the live rate. Its %CPU is per core (one busy core = 100), so it
      # is divided by the core count to match the total usage bar. rss from
      # ps is exact. Same-named processes (every browser tab, every editor)
      # are summed into one row per program.
      top -bn2 -d 0.4 -w 512 2>/dev/null \
        | awk -v cores="$(nproc)" '/^top -/ { f++ } f == 2 && $1 ~ /^[0-9]+$/ && NF >= 12 && $12 != "top" { v[$12] += $9 } END { for (k in v) print v[k] / cores, k }' \
        | sort -rn | head -n "$8" | awk '{ print "pcpu", $1, $2 }'
      ps -eo rss=,comm= | awk '{ v[$2] += $1 } END { for (k in v) print v[k], k }' \
        | sort -rn | head -n "$8" | awk '{ print "pmem", $1, $2 }'
    fi
  `

  function gib(kb) { return kb / 1048576 }

  function applyProbe(text) {
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].trim().split(/\s+/)
      if (f[0] === "temp") tempPath = f[1] || ""
      else if (f[0] === "disktemp") diskTempMap = f.slice(1).join(" ")
      else if (f[0] === "gpu") { gpuKind = f[1] || "none"; gpuBusyPath = f[2] || ""; gpuTempPath = f[3] || "" }
      else if (f[0] === "btop") btopAvailable = f[1] === "1"
    }
    gpuAvailable = gpuKind !== "none"
    sample()
  }

  function applySample(text) {
    var lines = String(text || "").split("\n")
    var list = null
    var temps = {}
    var cpuTop = null, memTop = null
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].trim().split(/\s+/)
      var n = f.slice(1).map(Number)
      if (f[0] === "cpu") {
        var idle = n[3] + n[4]
        var total = n.reduce(function(a, b) { return a + b }, 0)
        if (prevTotal >= 0 && total > prevTotal) cpu = Math.round((1 - (idle - prevIdle) / (total - prevTotal)) * 100)
        prevTotal = total
        prevIdle = idle
      } else if (f[0] === "temp") {
        cpuTemp = isFinite(n[0]) && f.length > 1 ? Math.round(n[0] / 1000) : -1
      } else if (f[0] === "mem") {
        memTotalGiB = gib(n[0]); memUsedGiB = gib(n[0] - n[1])
        memPercent = n[0] > 0 ? (n[0] - n[1]) / n[0] * 100 : 0
        swapTotalGiB = gib(n[2]); swapUsedGiB = gib(n[2] - n[3])
        swapPercent = n[2] > 0 ? (n[2] - n[3]) / n[2] * 100 : 0
      } else if (f[0] === "gpu") {
        gpuUtil = isFinite(n[0]) ? n[0] : 0
        gpuTemp = isFinite(n[1]) && n[1] >= 0 ? n[1] : -1
        gpuMemUsedGiB = isFinite(n[2]) ? n[2] / 1024 : 0
        gpuMemTotalGiB = isFinite(n[3]) ? n[3] / 1024 : 0
      } else if (f[0] === "disk" && f.length >= 5) {
        var used = Number(f[3]), size = Number(f[4])
        if (list === null) list = []
        list.push({ device: f[1], mount: f[2], usedGiB: used / 1073741824, totalGiB: size / 1073741824,
                    percent: size > 0 ? used / size * 100 : 0, temp: -1 })
      } else if (f[0] === "dtemp" && f.length >= 3 && isFinite(n[1])) {
        temps[f[1]] = Math.round(n[1] / 1000)
      } else if (f[0] === "pcpu" && f.length >= 3) {
        if (cpuTop === null) cpuTop = []
        cpuTop.push({ name: f.slice(2).join(" "), value: Number(f[1]).toFixed(1) })
      } else if (f[0] === "pmem" && f.length >= 3) {
        if (memTop === null) memTop = []
        memTop.push({ name: f.slice(2).join(" "), value: Math.round(Number(f[1]) / 1024) })
      }
    }
    if (cpuTop !== null) topCpu = cpuTop
    if (memTop !== null) topMem = memTop
    if (list !== null) {
      for (var d = 0; d < list.length; d++) {
        // /dev/nvme0n1p2 -> nvme0
        var m = /\/dev\/(nvme\d+)/.exec(list[d].device)
        if (m && temps[m[1]] !== undefined) list[d].temp = temps[m[1]]
      }
      disks = list
    }
  }

  function sample() {
    if (sampler.running) return
    var withDisks = disksPending || detailed || tick % diskEvery === 0
    disksPending = false
    tick += 1
    sampler.command = ["sh", "-c", root.sampleScript, "sh",
                       root.tempPath, root.gpuKind, root.gpuBusyPath, root.gpuTempPath,
                       withDisks ? "1" : "0", root.diskTempMap,
                       detailed ? "1" : "0", String(topCount)]
    sampler.running = true
  }

  onDetailedChanged: if (detailed) { disksPending = true; sample() }

  property Process prober: Process {
    command: ["sh", "-c", root.probeScript]
    running: true
    stdout: StdioCollector { onStreamFinished: root.applyProbe(text) }
  }

  property Process sampler: Process {
    id: sampler
    stdout: StdioCollector { onStreamFinished: root.applySample(text) }
  }

  property Timer ticker: Timer {
    interval: root.interval
    running: true
    repeat: true
    onTriggered: root.sample()
  }
}
