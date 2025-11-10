const base = require("./utils/base");
const config = require("./config/index");

(async () => {
  try {
    let tronWeb = await base.init(config.api, config.privateKey);
    let owner = tronWeb.defaultAddress.base58;
    let cross = config.cross.address !== "" ?
      await base.attach(config.cross.address) :
      await base.deploy("Cross", require("./abis/cross"), "Cross", {
        parameters: [
          tronWeb.address.toHex(config.cross.foundation)
        ]
      });

  } catch (e) {
    console.log(e)
  }

  process.exit(0)
})();

async function sleep(time) {
  await new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve()
    }, time * 1000)
  })
}
