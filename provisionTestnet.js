// deploys the contracts and also performs an /insanigration test/

const CASH_DECIMALS = 18
const DROPS_DECIMALS = 18

const assert = require('assert').strict;
const childProcess = require('child_process');
const ethers = require('ethers');

assert.equal(DROPS_DECIMALS % 2, 0);

// connect to local ganache instance
const provider = new ethers.providers.JsonRpcProvider('http://localhost:7545');

const adminWallet = new ethers.Wallet(process.env.PRIVATE_KEY_ADMIN, provider);
const aliceWallet = new ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);
const bobWallet = new ethers.Wallet(process.env.PRIVATE_KEY_BOB, provider);

(async () => {
  const [cashAbi, cashBytecode] = childProcess.execSync('vyper contracts/erc20.vy -f abi,bytecode')
    .toString('latin1')
    .split('\n');

  const cashContractFactory = new ethers.ContractFactory(cashAbi, cashBytecode, adminWallet);
  const cashContract = await cashContractFactory.deploy('Kovan Umbrella Cash', 'kUCSH', CASH_DECIMALS, 1000);

  console.log('Cash contract address:', cashContract.address);

  const [dropsAbi, dropsBytecode] = childProcess.execSync('vyper contracts/drops.vy -f abi,bytecode')
    .toString('latin1')
    .split('\n')

  const dropsContractFactory = new ethers.ContractFactory(dropsAbi, dropsBytecode, adminWallet);
  const dropsContract = await dropsContractFactory.deploy('Kovan Drops', 'kDROP', DROPS_DECIMALS, cashContract.address)

  console.log('Drops contract address:', dropsContract.address);

  await cashContract.deployed();
  await dropsContract.deployed();

  console.log('Deployed contracts')

  assert.equal(
    ethers.utils.formatUnits(
      (await cashContract.balanceOf(adminWallet.address)),
      (await cashContract.decimals()).toNumber()
    ).toString(),
    '1000.0'
  );

  const adminCashContract = cashContract.connect(adminWallet);

  await adminCashContract.approve(dropsContract.address, ethers.constants.MaxUint256);

  console.log('Approved cash');

  const adminDropsContract = dropsContract.connect(adminWallet);

  const mintTx = await adminDropsContract.mint(
    adminWallet.address,
    ethers.utils.parseUnits('100', CASH_DECIMALS),
    { gasLimit: 200000 }
  );
  await mintTx.wait()

  const dropsMinted = await dropsContract.balanceOf(adminWallet.address);

  assert.equal(
    ethers.utils.formatUnits(dropsMinted, DROPS_DECIMALS).toString(),
    '100.0'
  );

  console.log('Minted drops');

  const addAliceTx = await adminDropsContract.addToPool(aliceWallet.address);
  await addAliceTx.wait();

  const addBobTx = await adminDropsContract.addToPool(bobWallet.address);
  await addBobTx.wait();

  const transferDropsToAliceTx = await adminDropsContract.transfer(aliceWallet.address, dropsMinted.div(100));
  await transferDropsToAliceTx.wait();

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.shareBalanceOf(aliceWallet.address),
      DROPS_DECIMALS / 2
    ),
    '1.0'
  )

  console.log('Transferred drops to Alice')

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.withdrawableCashOf(aliceWallet.address),
      CASH_DECIMALS
    ),
    '100.0'
  )

  const aliceDropsContract = dropsContract.connect(aliceWallet);
  const withdrawAliceDonationsTx = await aliceDropsContract.withdrawDonations(
    ethers.utils.bigNumberify('1000000000000000000'), // 1 UCSH
    { gasLimit: 200000 }
  );
  await withdrawAliceDonationsTx.wait();

  console.log('Alice withdrew cash');

  const transferDropsToBobTx = await adminDropsContract.transfer(bobWallet.address, dropsMinted.div(100));
  await transferDropsToBobTx.wait();

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.shareBalanceOf(bobWallet.address),
      DROPS_DECIMALS / 2
    ),
    '1.0'
  )

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.withdrawableCashOf(bobWallet.address),
      CASH_DECIMALS
    ),
    '0.0'
  )

  console.log('Transferred drops to Bob')

  const mintMoreTx = await adminDropsContract.mint(
    adminWallet.address,
    ethers.utils.parseUnits('100', CASH_DECIMALS),
    { gasLimit: 200000 }
  );
  await mintMoreTx.wait()

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.withdrawableCashOf(bobWallet.address),
      CASH_DECIMALS
    ),
    '50.0'
  )

  const bobDropsContract = dropsContract.connect(bobWallet);
  const withdrawBobDonationsTx = await bobDropsContract.withdrawDonations(
    ethers.utils.bigNumberify('50000000000000000000'), // 50 UCSH
    { gasLimit: 200000 }
  );
  await withdrawBobDonationsTx.wait();

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.withdrawableCashOf(aliceWallet.address),
      CASH_DECIMALS
    ),
    '99.0'
  )

  assert.equal(
    ethers.utils.formatUnits(
      await dropsContract.withdrawableCashOf(bobWallet.address),
      CASH_DECIMALS
    ),
    '0.0'
  )
})();
