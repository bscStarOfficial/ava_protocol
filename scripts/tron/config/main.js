module.exports = {
  START_BLOCK: 42031500,
  api: "https://api.trongrid.io",
  privateKey: process.env.PRIVATE_KEY_TRONGRID,
  opt: {
    feeLimit: 1500_000_000,
    callValue: 0,
    shouldPollResponse: false
  },
  cross: {
    address: "",
    foundation: "",
  }
}
