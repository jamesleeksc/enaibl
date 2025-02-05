class OpenAiService
  def initialize
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:open_ai, :api_key))
  end

  def classify_document(text)
    classification_keys = {
      "carrier_quote_email" => "true|false",
      "customer_quote_pdf" => "true|false",
      "customer_quote_confirmation_email" => "true|false",
      "master_bill_of_lading" => "true|false",
      "house_bill_of_lading" => "true|false",
      "commercial_invoice" => "true|false",
      "packing_list" => "true|false",
      "isf_excel" => "true|false",
      "isf_transmission_pdf" => "true|false",
      "customs_clearance" => "true|false",
      "proof_of_delivery" => "true|false",
      "misc_relevant" => "true|false",
      "irrelevant" => "true|false"
    }.to_s

    return "" if text.blank?
    text = text[0..1000] if text.size > 1000

    print("classifying #{text}")

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are an AI assistant trained to classify logistics documents into predefined categories and output the result as a JSON object in string form."
          },
          {
            role: "user",
            content: "Classify the following text into one of the predefined categories and return the result as a JSON string in the following format: #{classification_keys}.\n\n#{text}\n\n"
          }
        ],
        max_tokens: 1500
      }
    )

    response.dig("choices", 0, "message", "content").strip
  end

  def extract_shipment(text)
    model = "gpt-4o-mini"
    prompt_record = Prompt.new(model: model, input: text, task_type: "extract_shipment")
    response = @client.chat(
      parameters: {
        model: model,
        messages: [
          {
            role: "system",
            content: "You are an AI assistant trained to extract shipment information from logistics documents and output the result as a JSON object."
          },
          {
            role: "user",
            content: extract_prompt(text)
          }
        ],
        max_tokens: 1500
      }
    )

    # TODO: Show multiple choices?
    choices = response.dig("choices")
    stringified = response.dig("choices", 0, "message", "content").strip
    prompt_record.output = choices.to_s
    prompt_record.save
    response = convert_to_json(stringified)
  end

  def convert_to_json(text)
    begin
      sanitized = text.gsub("```json", "").gsub("```", "").gsub("\n", "")
      return {} if sanitized.blank?
      result = JSON.parse(sanitized)
    rescue JSON::ParserError
      result = {}
    end
    result
  end

  private
  def extract_prompt(text)
    prompt = <<-PROMPT
    Extract the following information from the provided text. Leave any field blank if the information is not present or cannot be determined accurately.

    Text:
    #{text}

    Output format (JSON):
    {
      "origin_code": "",
      "origin_name": "",
      "origin_iata": "",
      "origin_address_1": "",
      "origin_address_2": "",
      "origin_postcode": "",
      "origin_city": "",
      "origin_state_code": "",
      "origin_country_code": "",
      "destination_code": "",
      "destination_name": "",
      "destination_iata": "",
      "destination_address_1": "",
      "destination_address_2": "",
      "destination_postcode": "",
      "destination_city": "",
      "destination_state_code": "",
      "destination_country_code": "",
      "transport_type": "",
      "container_type": "",
      "shipment_type": "",
      "shipper_code": "",
      "consignee_code": "",
      "customer_code": "",
      "weight": "",
      "weight_units": "",
      "volume": "",
      "volume_units": "",
      "length": "",
      "width": "",
      "height": "",
      "measurement_units": "",
      "po_number": "",
      "bol_number": "",
      "shipped_date": "",
      "issue_date": "",
      "eta": "",
      "etd": "",
      "description": "",
      "commodity_code": "",
      "initial_platform": "",
      "destination_platform": "",
      "platform_shipment_id": "",
      "platform_consol_id": ""
    }
    PROMPT
  end
end
