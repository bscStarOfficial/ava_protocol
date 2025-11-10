module.exports = {
  START_BLOCK: 25457429,
  api: "https://api.shasta.trongrid.io",
  privateKey: process.env.PRIVATE_KEY_SHASTA,
  opt: {
    feeLimit: 1000_000_000,
    callValue: 0,
    shouldPollResponse: false
  },
  cross: {
    address: "",
    foundation: "TKTSXhMM9YPvh5Si8QVnTgW8CavexKte9C",
  }
}
