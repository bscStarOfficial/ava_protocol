const {ethers} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments, getChainId, getUnnamedAccounts}) => {
  const {deploy} = deployments;
  let {deployer} = await getNamedAccounts();
  const chainId = await getChainId()
  if (chainId != 56) return;

  await deploy('Manager', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: []
        }
      }
    },
    log: true,
  });
  let manager = await ethers.getContract('Manager');
  let ava = await ethers.getContract('AVA');

  // 部署3个空合约账号设置ExcludedFromFee，为后续业务做准备
  for (let i = 0; i < 3; i++) {
    let name = 'Empty' + i
    await deploy(name, {
      contract: 'Empty',
      from: deployer,
      args: [],
      proxy: {
        proxyContract: 'OpenZeppelinTransparentProxy',
        execute: {
          init: {
            methodName: 'initialize',
            args: [manager.address]
          }
        }
      },
      log: true,
    });

    let empty = await ethers.getContract(name);
    if (!await ava.isExcludedFromFee(empty.address)) {
      let tx = await ava.excludeFromFee(empty.address);
      console.log(name, tx.hash);
      await tx.wait()
    }
  }


};
module.exports.tags = ['empty'];
