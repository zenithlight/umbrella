<script>
	import ethers from 'ethers';

	const abi = '[{"name": "Transfer", "inputs": [{"type": "address", "name": "_from", "indexed": true}, {"type": "address", "name": "_to", "indexed": true}, {"type": "uint256", "name": "_value", "indexed": false}], "anonymous": false, "type": "event"}, {"name": "Approval", "inputs": [{"type": "address", "name": "_owner", "indexed": true}, {"type": "address", "name": "_spender", "indexed": true}, {"type": "uint256", "name": "_value", "indexed": false}], "anonymous": false, "type": "event"}, {"name": "WhitelistAdd", "inputs": [{"type": "address", "name": "_who", "indexed": true}], "anonymous": false, "type": "event"}, {"name": "WhitelistRemove", "inputs": [{"type": "address", "name": "_who", "indexed": true}], "anonymous": false, "type": "event"}, {"name": "getCashPerShare", "outputs": [{"type": "uint256", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 20215}, {"name": "withdrawableCashOf", "outputs": [{"type": "uint256", "name": ""}], "inputs": [{"type": "address", "name": "who"}], "constant": true, "payable": false, "type": "function", "gas": 61605}, {"outputs": [], "inputs": [{"type": "string", "name": "_name"}, {"type": "string", "name": "_symbol"}, {"type": "uint256", "name": "_decimals"}, {"type": "address", "name": "_cash_token"}], "constant": false, "payable": false, "type": "constructor"}, {"name": "totalSupply", "outputs": [{"type": "uint256", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 1391}, {"name": "setAdmin", "outputs": [], "inputs": [{"type": "address", "name": "who"}], "constant": false, "payable": false, "type": "function", "gas": 36517}, {"name": "addToPool", "outputs": [], "inputs": [{"type": "address", "name": "who"}], "constant": false, "payable": false, "type": "function", "gas": 760564}, {"name": "removeFromPool", "outputs": [], "inputs": [{"type": "address", "name": "who"}], "constant": false, "payable": false, "type": "function", "gas": 95711}, {"name": "transfer", "outputs": [{"type": "bool", "name": ""}], "inputs": [{"type": "address", "name": "_to"}, {"type": "uint256", "name": "_value"}], "constant": false, "payable": false, "type": "function", "gas": 797734}, {"name": "mint", "outputs": [], "inputs": [{"type": "address", "name": "_to"}, {"type": "uint256", "name": "_value"}], "constant": false, "payable": false, "type": "function", "gas": 80361}, {"name": "withdrawDonations", "outputs": [], "inputs": [{"type": "uint256", "name": "amount"}], "constant": false, "payable": false, "type": "function", "gas": 138472}, {"name": "transferFrom", "outputs": [{"type": "bool", "name": ""}], "inputs": [{"type": "address", "name": "_from"}, {"type": "address", "name": "_to"}, {"type": "uint256", "name": "_value"}], "constant": false, "payable": false, "type": "function", "gas": 879}, {"name": "approve", "outputs": [{"type": "bool", "name": ""}], "inputs": [{"type": "address", "name": "_spender"}, {"type": "uint256", "name": "_value"}], "constant": false, "payable": false, "type": "function", "gas": 870}, {"name": "allowance", "outputs": [{"type": "uint256", "name": ""}], "inputs": [{"type": "address", "name": "_owner"}, {"type": "address", "name": "_spender"}], "constant": true, "payable": false, "type": "function", "gas": 939}, {"name": "name", "outputs": [{"type": "string", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 8093}, {"name": "symbol", "outputs": [{"type": "string", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 7146}, {"name": "decimals", "outputs": [{"type": "uint256", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 1751}, {"name": "admin", "outputs": [{"type": "address", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 1781}, {"name": "cashToken", "outputs": [{"type": "address", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 1811}, {"name": "balanceOf", "outputs": [{"type": "uint256", "name": ""}], "inputs": [{"type": "address", "name": "arg0"}], "constant": true, "payable": false, "type": "function", "gas": 1995}, {"name": "whitelist", "outputs": [{"type": "bool", "name": ""}], "inputs": [{"type": "address", "name": "arg0"}], "constant": true, "payable": false, "type": "function", "gas": 2025}, {"name": "shareBalanceOf", "outputs": [{"type": "uint256", "name": ""}], "inputs": [{"type": "address", "name": "arg0"}], "constant": true, "payable": false, "type": "function", "gas": 2055}, {"name": "total_share_supply", "outputs": [{"type": "uint256", "name": ""}], "inputs": [], "constant": true, "payable": false, "type": "function", "gas": 1931}]';

	const provider = new ethers.providers.Web3Provider(web3.currentProvider);
	const signer = provider.getSigner();

	const addressData = [];

	let myCash = 'Loading...';
	let myDrops = 'Loading...';

	let contract;
	let cashContract;

	const approve = async () => {
		const myCashContract = cashContract.connect(signer);

		await myCashContract.approve(contract.address, ethers.constants.MaxUint256, { gasLimit: 200000 });
	}

	const donate = async () => {
		const amountToDonate = prompt('How much cash to donate?');

		const myDropsContract = contract.connect(signer);
		await myDropsContract.mint(await signer.getAddress(), ethers.utils.parseEther(amountToDonate), { gasLimit: 200000 });
	}

	const award = async (address) => {
		const amountToAward = prompt('How many drops to award?');

		const myDropsContract = contract.connect(signer);
		await myDropsContract.transfer(address, ethers.utils.parseEther(amountToAward), { gasLimit: 797734 });
	}

	const withdraw = async (address) => {
		const amountToAward = prompt('How much cash to withdraw?');

		const myDropsContract = contract.connect(signer);
		await myDropsContract.withdrawDonations(address, { gasLimit: 200000 });
	}

	(async () => {
		await window.ethereum.enable()

		const response = await fetch('/constants.json');
		const constants = await response.json();

		contract = new ethers.Contract(constants.dropsTokenAddress, abi, provider);
		cashContract = new ethers.Contract(constants.cashTokenAddress, abi, provider);

		const dropsDecimals = (await contract.decimals()).toNumber();
		const cashDecimals = (await cashContract.decimals()).toNumber();

		const totalShareSupply = await contract.total_share_supply();

		for (let address in constants.whitelist) {
			const addressDatum = {
				'address': address,
				'name': constants.whitelist[address]
			};

			addressDatum.drops = ethers.utils.formatUnits(await contract.balanceOf(address), dropsDecimals);

			const shares = await contract.shareBalanceOf(address);

			addressDatum.shares = ethers.utils.formatUnits(shares, dropsDecimals / 2);
			addressDatum.stake = shares.toNumber() / totalShareSupply.toNumber();

			const cash = await contract.withdrawableCashOf(address);

			addressDatum.cash = ethers.utils.formatUnits(cash, cashDecimals);

			addressData.push(addressDatum);

			const myAddress = await signer.getAddress();

			myCash = await ethers.utils.formatUnits(
				await cashContract.balanceOf(myAddress),
				cashDecimals
			);

			myDrops = await ethers.utils.formatUnits(
				await contract.balanceOf(myAddress),
				dropsDecimals
			);
		}

		addressData = addressData;
	})();
</script>

<style>
	#container {
    width: 800px;
    margin: auto;
    font-family: monospace;
    padding-top: 50px;
		font-size: 18px;
	}

	h1 {
		text-align: center;
		margin-bottom: 50px;
	}

	#creators {
		margin: 50px 0;
	}

	#creators > div {
		display: grid;
		grid-template-columns: 1.25fr 1fr auto;
		align-items: center;
		height: 100px;
	}

	.info {
		color: #999;
	}

	button {
		background: #26e;
		padding: 6px;
		font-family: monospace;
		color: white;
		border: none;
		border-radius: 4px;
		font-size: 14px;
		width: 200px;
		margin-bottom: 5px;
	}

	button:hover {
		background: #38f;
	}

	button:active {
		background: #12d;
	}

	#mine {
		text-align: center;
	}

	#mine button {
		margin: 10px 0 -5px 0;
		background: #691;
	}

	#mine button:hover {
		background: #8a2;
	}

	#mine button:active {
		background: #570;
	}
</style>

<div id="container">
  <h1>Mathematicians Guild Umbrella</h1>
	<div id="mine">
		<div>My Cash: {myCash}</div>
		<div>My Drops: {myDrops}</div>
		<div><button on:click={approve}>Approve cash</button></div>
		<button on:click={donate}>Donate to pool</button>
	</div>
	<div id="creators">
		{#each addressData as address}
			<div>
				<div>{address.name}</div>
				<div class="info">
					<div>Drops: {parseFloat(address.drops).toFixed(2)}</div>
					<div>Shares: {parseFloat(address.shares).toFixed(2)}</div>
					<div>Stake: {(address.stake * 100).toFixed(2)}%</div>
					<div>Cash: {parseFloat(address.cash).toFixed(2)}</div>
				</div>
				<div>
					<div><button on:click={() => {award(address.address)}}>Award Drops</button></div>
					<div><button on:click={() => {withdraw(address.address)}}>Withdraw cash</button></div>
				</div>
			</div>
		{/each}
	</div>
</div>
