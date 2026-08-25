const assert = require("node:assert/strict")
const model = require("../TaxModel.js")

assert.equal(model.WALLET, "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38")
assert.equal(model.isWallet(model.WALLET), true)
assert.equal(model.isWallet(model.WALLET + "0"), false)
assert.deepEqual(model.assessment(1040), {
  filing: "OLG-001040",
  rate: 88,
  risk: "ELEVATED"
})
assert.equal(model.assessment(-1).filing, "OLG-000000")
assert.equal(model.splitWallet(model.WALLET).replace(/\n/g, ""), model.WALLET)
assert.deepEqual(model.parseMetrics("1.25|61.4|42%|90061|88"), {
  load: "1.25",
  memory: 61,
  disk: 42,
  uptime: "1D 1H",
  battery: "88%"
})
assert.equal(model.parseMetrics("bad|999|-2|0|-1").memory, 100)
assert.equal(model.parseMetrics("bad|999|-2|0|-1").disk, 0)
assert.equal(model.parseMetrics("bad|999|-2|0|-1").battery, "DESKTOP")
assert.equal(model.scene(-1).id, "board-meeting")
assert.equal(model.scene(4).id, "trickle-up")
assert.equal(model.marketRow(5).symbol, "LABR")

console.log("PASS - Oligarchy operating model")
