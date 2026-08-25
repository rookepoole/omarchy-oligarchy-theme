var WALLET = "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38"

var SCENES = [
  {
    id: "trickle-up",
    kicker: "ECONOMIC MOBILITY SIMULATOR",
    title: "TRICKLE-UP ECONOMY",
    subtitle: "Please remain stationary while liquidity rises to its natural owner."
  },
  {
    id: "market-maker",
    kicker: "CONTINUOUS PRICE DISCOVERY",
    title: "THE MARKET HAS SPOKEN",
    subtitle: "The market would like to remain anonymous."
  },
  {
    id: "shell-orbit",
    kicker: "BENEFICIAL OWNERSHIP TOPOLOGY",
    title: "SHELL COMPANY ORBITAL",
    subtitle: "Nothing to disclose. Everything is in motion."
  },
  {
    id: "board-meeting",
    kicker: "ANNUAL GENERAL MEETING",
    title: "MOTION CARRIED 1–0",
    subtitle: "Minority shareholders were represented by a decorative chair."
  }
]

var MARKET_ROWS = [
  { symbol: "LABR", name: "Human capital", price: "LEASED", change: "+12.4%" },
  { symbol: "HOME", name: "Starter homes", price: "SHORT", change: "+41.0%" },
  { symbol: "YCHT", name: "Marine deductions", price: "LONG", change: "+8.8%" },
  { symbol: "TAX", name: "Effective rate", price: "0.01%", change: "BEAT" },
  { symbol: "REG", name: "Regulatory capture", price: "OWNED", change: "+99.9%" }
]

var PORTFOLIOS = [
  { id: 1, symbol: "HOLDCO", name: "Core holding company" },
  { id: 2, symbol: "MEDIA", name: "Narrative operations" },
  { id: 3, symbol: "LABOR", name: "Human-capital leasing" },
  { id: 4, symbol: "YACHT", name: "Marine deductions" },
  { id: 5, symbol: "CAYMAN", name: "Disclosure services" }
]

function clampSerial(value) {
  var n = parseInt(String(value), 10)
  if (!isFinite(n) || n < 0) return 0
  return n % 1000000
}

function assessment(serial) {
  var n = clampSerial(serial)
  var rate = 37 + ((n * 17 + 11) % 63)
  var risk = rate >= 90 ? "INEVITABLE" : rate >= 70 ? "ELEVATED" : "OPTIMAL"
  return {
    filing: "OLG-" + ("000000" + n).slice(-6),
    rate: rate,
    risk: risk
  }
}

function splitWallet(value) {
  var text = String(value || "")
  return text.slice(0, 10) + "\n" + text.slice(10, 18) + "\n" +
    text.slice(18, 26) + "\n" + text.slice(26, 34) + "\n" + text.slice(34)
}

function isWallet(value) {
  return /^0x[0-9A-Fa-f]{40}$/.test(String(value || ""))
}

function clampPercent(value) {
  var n = parseFloat(String(value))
  if (!isFinite(n)) return 0
  return Math.max(0, Math.min(100, Math.round(n)))
}

function parseMetrics(value) {
  var parts = String(value || "").trim().split("|")
  var uptimeSeconds = Math.max(0, Math.floor(Number(parts[3]) || 0))
  var days = Math.floor(uptimeSeconds / 86400)
  var hours = Math.floor((uptimeSeconds % 86400) / 3600)
  var battery = Number(parts[4])
  return {
    load: Math.max(0, Number(parts[0]) || 0).toFixed(2),
    memory: clampPercent(parts[1]),
    disk: clampPercent(parts[2]),
    uptime: days > 0 ? days + "D " + hours + "H" : hours + "H",
    battery: isFinite(battery) && battery >= 0 ? clampPercent(battery) + "%" : "DESKTOP"
  }
}

function scene(index) {
  var n = parseInt(String(index), 10)
  if (!isFinite(n)) n = 0
  n = ((n % SCENES.length) + SCENES.length) % SCENES.length
  return SCENES[n]
}

function marketRow(index) {
  var n = parseInt(String(index), 10)
  if (!isFinite(n)) n = 0
  n = ((n % MARKET_ROWS.length) + MARKET_ROWS.length) % MARKET_ROWS.length
  return MARKET_ROWS[n]
}

function portfolio(index) {
  var n = parseInt(String(index), 10)
  if (!isFinite(n)) n = 0
  n = ((n % PORTFOLIOS.length) + PORTFOLIOS.length) % PORTFOLIOS.length
  return PORTFOLIOS[n]
}

function focusSeconds(value) {
  var n = Math.floor(Number(value))
  if (!isFinite(n)) return 0
  return Math.max(0, Math.min(99 * 60 + 59, n))
}

function formatFocusTime(value) {
  var seconds = focusSeconds(value)
  var minutes = Math.floor(seconds / 60)
  var remainder = seconds % 60
  return (minutes < 10 ? "0" : "") + minutes + ":" +
    (remainder < 10 ? "0" : "") + remainder
}

function focusProgress(remaining, duration) {
  var total = focusSeconds(duration)
  if (total <= 0) return 0
  return Math.max(0, Math.min(1, 1 - focusSeconds(remaining) / total))
}

if (typeof module !== "undefined") {
  module.exports = {
    WALLET: WALLET,
    clampSerial: clampSerial,
    assessment: assessment,
    splitWallet: splitWallet,
    isWallet: isWallet,
    clampPercent: clampPercent,
    parseMetrics: parseMetrics,
    scene: scene,
    marketRow: marketRow,
    portfolio: portfolio,
    focusSeconds: focusSeconds,
    formatFocusTime: formatFocusTime,
    focusProgress: focusProgress,
    SCENES: SCENES,
    MARKET_ROWS: MARKET_ROWS,
    PORTFOLIOS: PORTFOLIOS
  }
}
