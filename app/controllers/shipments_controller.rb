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
      email = @email
    end

    to = "to: #{email.to}"
    from = "from: #{email.from}"
    subject = "subject: #{email.subject}"
    body = "body: #{email.body}"
    email_string = [to, from, subject, body, email.date].join("\n")
    binding.pry
    shipment_data = OpenAiService.new.extract_shipment(email_string)

    shipment_data = clean_and_format_shipment_data(shipment_data)

    @shipment.assign_attributes(shipment_data)
  end

  def show
  end

  def update
  end

  private
  def clean_and_format_shipment_data(data)
    data["origin_location"] = origin_location_from_data(data)
    data["destination_location"] = destination_location_from_data(data)
    # sanitize to shipment params
    data = data.select { |k, v| Shipment.column_names.include?(k) }
  end

  def origin_location_from_data(data)
    data = data.select { |k, v| k.match?(/origin/i) && v.present?}
    data.transform_keys! { |k| k.gsub('origin_', '') }
    data["state"] = data.delete("state_code")
    data["country"] = data.delete("country_code")

    location = Location.find_by(code: data['code'])
    location ||= Location.find_by(iata: data['iata'])

    return location.code if location
    location = Organization.find_by(data)
    location ||= Organization.find_by(data.except("name"))

    location.unloco
  end

  def destination_location_from_data(data)
    data = data.select { |k, v| k.match?(/destination/i) && v.present?}
    data.transform_keys! { |k| k.gsub('destination_', '') }
    data["state"] = data.delete("state_code")
    data["country"] = data.delete("country_code")

    location = Location.find_by(code: data['code'])
    location ||= Location.find_by(iata: data['iata'])

    return location.code if location
    location = Organization.find_by(data)
    location ||= Organization.find_by(data.except("name"))

    location.unloco
  end

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