// 底池10万U / 200万 BTN
const sql = require("../sql");

(async () => {
  await truncate();
  await buyIncrease();
  await sellIncrease();

  process.exit(0);
})();

async function sellIncrease() {
  let uReserve = 10_0000;
  let bReserve = 200_0000;
  let price = uReserve / bReserve;

  await insertSell({uReserve, bReserve, price, input: 0});

  // 每次卖5万，卖20次
  for (let i = 0; i < 20; i++) {
    let input = 5_0000;
    let b = input;
    let u = b / bReserve * uReserve;
    uReserve -= u;
    bReserve -= b;

    // 买入22.5%U
    let uBuy = u * 0.225;
    let uReserve_ = uReserve + uBuy;
    let bReserve_ = uReserve * bReserve / uReserve_;

    let price = uReserve_ / bReserve_;

    uReserve = uReserve_;
    bReserve = bReserve_;

    await insertSell({uReserve, bReserve, price, input});
  }
}

async function buyIncrease() {
  let uReserve = 10_0000;
  let bReserve = 200_0000;
  let price = uReserve / bReserve;

  await insertBuy({uReserve, bReserve, price, input: 0});

  for (let i = 0; i < 300; i++) {
    let input = 1_000;
    let u = input / 2;
    // 买入50%U

    let uReserve_ = uReserve + u;
    let bReserve_ = uReserve * bReserve / uReserve_;

    // 添加流动性
    let bReservePlus = u / uReserve_ * bReserve_;
    let uReservePlus = u;

    uReserve_ += uReservePlus;
    bReserve_ += bReservePlus;
    let price = uReserve_ / bReserve_;

    uReserve = uReserve_;
    bReserve = bReserve_;
    await insertBuy({uReserve, bReserve, price, input});
  }
}

async function insertBuy({uReserve, bReserve, input, price}) {
  await sql.query(
    'INSERT INTO `btn`.`temp_buy` (`uReserve`, `bReserve`, `input`, `price`) VALUES (?,?,?,?);',
    [uReserve, bReserve, input, price]
  )
}

async function insertSell({uReserve, bReserve, input, price}) {
  await sql.query(
    'INSERT INTO `btn`.`temp_sell` (`uReserve`, `bReserve`, `input`, `price`) VALUES (?,?,?,?);',
    [uReserve, bReserve, input, price]
  )
}

async function truncate() {
  await sql.query('truncate `btn`.`temp_sell`;')
  await sql.query('truncate `btn`.`temp_buy`;')
}
