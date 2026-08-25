var WALLET = "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38"

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

if (typeof module !== "undefined") {
  module.exports = {
    WALLET: WALLET,
    clampSerial: clampSerial,
    assessment: assessment,
    splitWallet: splitWallet,
    isWallet: isWallet
  }
}
