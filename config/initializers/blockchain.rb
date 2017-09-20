config_path = Rails.root.join('config', "blockchain.yml")

if File.exists? config_path
  BLOCKCHAIN_CONFIG = YAML.load_file(config_path)[Rails.env]
else
  BLOCKCHAIN_CONFIG = {}
end
