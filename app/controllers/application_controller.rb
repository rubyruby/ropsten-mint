class ApplicationController < ActionController::API
  def mint
    blockchain = Blockchain.new
    address = params[:address]

    if !blockchain.can_send_to?(address)
      render json: { success: false, error: "This address can't be used." }
    elsif blockchain.not_enough_ether?
      render json: { success: false, error: "Not enough ether. Try again later." }
    else
      tx = blockchain.send(address)
      render json: { success: true, tx: tx }
    end
  end
end
