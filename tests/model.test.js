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

console.log("PASS - Tax Department model")
