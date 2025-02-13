class ClientAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client_account, only: %i[index show edit update destroy]

  def show
  end

  def index
    if current_user.client_account.blank?
      redirect_to new_client_account_path
      return
    end
  end

  def new
    @client_account = ClientAccount.new
  end

  def edit
  end

  def create
    @client_account = ClientAccount.new(client_account_params)

    if @client_account.save
      current_user.update(client_account: @client_account)

      redirect_to client_accounts_path
    else
      render 'new'
    end
  end

  def destroy
  end

  def update
    if @client_account.update(client_account_params)
      redirect_to client_accounts_path
    else
      render 'edit'
    end
  end

  private
  def client_account_params
    # :id, :full_name, :city, :state, :country_region, :address_1, :address_2, :email, :phone, :postcode, :mobile, :website_url, :additional_address_info, :notes, :eadaptor_url, :eadaptor_username, :eadaptor_password, :eadaptor_endpoint, :created_at, :updated_at
    params.require(:client_account).permit(
      :full_name,
      :city,
      :state,
      :country_region,
      :address_1,
      :address_2,
      :email,
      :phone,
      :postcode,
      :mobile,
      :website_url,
      :additional_address_info,
      :notes,
      :eadaptor_url,
      :eadaptor_username,
      :eadaptor_password,
      :eadaptor_endpoint,
      :alias_organizations,
      :branch_shortcode
    )
  end

  def set_client_account
    @client_account = current_user.client_account
  end
end
