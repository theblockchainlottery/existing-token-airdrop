# existing-token-airdrop
Contract can be used to airdrop already existing erc20 tokens.

First, deploy the contract with your desired airdrop token allocation amount, the runtime for the airdrop in seconds, the maximum subscriber count to the airdrop, and most importantly the ERC20 token contract address of the token you want to airdrop as the 4 constructor function parameters. 
Next, from the same wallet(as you are now the owner), simply send the contract the SAME amount of tokens that you previously specified to be allocated during contract deployment. The contract will now be funded with the sent tokens. 
Then, anyone can use the newSubscriber function to request airdropped tokens, they will pay any required gas fees, and recieve their tokens.
You can also use the manualDrop function to manually airdrop tokens to anyone who requests it, using their Ethereum address as the function parameter.
If the airdrop duration ends, and tokens are left. You (as the owner) can call the sweepTokens function to retrieve them.
The amount of tokens distributed to each person will be automatically calculated based on - token allocation / maximum subscribers
