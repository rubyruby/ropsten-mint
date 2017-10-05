class Blockchain
  GAS_PRICE = 200000000000
  GAS_LIMIT = 1000000

  def initialize
    @address = BLOCKCHAIN_CONFIG['account_address']
    @private_key_hex = BLOCKCHAIN_CONFIG['account_private_key']
    @client = Ethereum::IpcClient.new("#{ENV['HOME']}/.ethereum/testnet/geth.ipc", false)
    @formatter = Ethereum::Formatter.new

    contract_json = JSON.parse(File.read('app/blockchain/contracts/mint.json'))
    contract_address = contract_json['address']
    contract_abi = contract_json['abi']

    @contract_instance = Ethereum::Contract.create(name: "Mint", address: contract_address, abi: contract_abi)
    @contract_instance.gas_price = GAS_PRICE
    @contract_instance.gas_limit = GAS_LIMIT
  end

  def not_enough_ether?
    balance < 0.2
  end

  def can_send_to?(address)
    @contract_instance.call.can_send_to(address)
  end

  def send(address)
    tx = signed_transactions do |contract_instance|
      contract_instance.transact.send_to(address)
    end
    tx.id
  end

  def balance
    @formatter.from_wei(@client.eth_get_balance(@contract_instance.address)["result"].to_i(16)).to_d
  end

  private

  def signed_transactions
    key = Eth::Key.new priv: @private_key_hex
    @contract_instance.key = key
    tx = yield(@contract_instance)
    @contract_instance.key = nil
    tx
  end
end
