class ShipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shipment, only: %i[show edit update destroy]

  def create
  end

  def destroy
  end

  def edit
  end

  def index
    @shipments = account_shipments
  end

  def new
    if params[:email_id]
      @email = load_user_email(params[:email_id])
    end

    @shipment = Shipment.new(client_account: current_user.client_account)

    if @email
      @shipment.emails << @email
    end


    binding.pry

    # TODO: load data from email
  end

  def show
  end

  def update
  end

  private
  def set_shipment
    @shipment = account_shipments.find_by(params[:id])
  end

  def account_shipments
    Shipment.where(client_account_id: current_user.client_account_id)
  end

  def load_user_email(id)
    email = Email.find_by(id: id)
    return unless email.owned_by?(current_user)
    email
  end
end