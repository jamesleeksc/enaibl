class ShipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shipment, only: %i[show edit update destroy]

  def create
    @shipment = Shipment.new(shipment_params)
    @shipment.client_account = current_user.client_account
    @email = load_user_email(params[:email_id]) if params[:email_id]
    @shipment.emails << @email if @email
    @shipment.save
    redirect_to shipment_path(@shipment)
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
      @documents = email.documents.where.not(content: nil).where.not(irrelevant: true)
    end

    to = "to: #{email.to}"
    from = "from: #{email.from}"
    subject = "subject: #{email.subject}"
    body = "body: #{email.body}"
    email_string = [to, from, subject, body, email.date].join("\n")
    shipment_data = OpenAiService.new.extract_shipment(email_string)
    @documents.each do |doc|
      begin
        shipment_data.merge!(OpenAiService.new.extract_shipment(doc.content))
      rescue
        next
      end
    end

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
    return unless data.present? && data.is_a?(Hash)
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
    return unless data.present? && data.is_a?(Hash)
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
    @shipment = account_shipments.find_by(id: params[:id])
  end

  def account_shipments
    Shipment.where(client_account_id: current_user.client_account_id)
  end

  def load_user_email(id)
    email = Email.find_by(id: id)
    return unless email.owned_by?(current_user)
    email
  end

  def shipment_params
    params.require(:shipment).permit(
      :platform_shipment_id,
      :platform_consol_id,
      :origin_code,
      :destination_code,
      :transport_type,
      :container_type,
      :shipment_type,
      :shipper_code,
      :consignee_code,
      :customer_code,
      :weight,
      :weight_units,
      :volume,
      :volume_units,
      :length,
      :width,
      :height,
      :measurement_units,
      :po_number,
      :bol_number,
      :shipped_date,
      :issue_date,
      :eta,
      :etd,
      :description,
      :commodity_code,
      :initial_platform,
      :destination_platform,
      :line_items
    )
  end
end