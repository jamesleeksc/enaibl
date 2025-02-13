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
      "shipping_invoice" => "true|false",
      "other_invoice" => "true|false",
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
            content: "Classify the following text as one or more of the following predefined categories and return the result as a JSON string in the following format: #{classification_keys}.\n\n#{text}\n\n"
          }
        ],
        max_tokens: 1500
      }
    )

    response.dig("choices", 0, "message", "content").strip
  end

  def pod?(text)
    # TODO: modify to include image processing for stamps and signatures
    begin
      model = "gpt-4o-mini"
      prompt_record = Prompt.new(model: model, input: text, task_type: "pod")
      text = text[0..1000] if text.size > 1000
      response = @client.chat(
        parameters: {
          model: model,
          messages: [
            {
              role: "system",
              content: "You are an AI assistant trained to determine if a document is a proof of delivery. A proof of delivery has a stamp or signature, as well as a date. Please respond with 'true' if it is a proof of delivery, and 'false' otherwise."
            },
            { role: "user", content: "Is the following text/document a proof of delivery? #{text}" }],
          max_tokens: 1000
        }
      )
      response.dig("choices", 0, "message", "content").strip
    rescue => e
      binding.pry
      puts "Error classifying pod: #{e.message}"
      return false
    end
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
        max_tokens: 3000
      }
    )

    # TODO: Show multiple choices?
    choices = response.dig("choices")
    stringified = response.dig("choices", 0, "message", "content").strip
    prompt_record.output = choices.to_s
    prompt_record.save
    response = convert_to_json(stringified)
    begin
      if response["line_items"]
        response["line_items"] = response["line_items"].map { |item| convert_to_json(item) }
      end
    rescue JSON::ParserError
      puts "Error parsing line items"
      response["line_items"] = []
    end

    response
  end

  def convert_to_json(text)
    if text.is_a?(Hash)
      return text
    end

    begin
      sanitized = text.gsub("```json", "").gsub("```", "").gsub("\n", "")
      return {} if sanitized.blank?
      result = JSON.parse(sanitized)
    rescue JSON::ParserError
      result = {}
    end
    result
  end

  def extract_invoice(text)
    model = "gpt-4o-mini"
    prompt_record = Prompt.new(model: model, input: text, task_type: "extract_invoice")
    response = @client.chat(
      parameters: {
        model: model,
        messages: [
          {
            role: "system",
            content: "You are an AI assistant trained to extract invoice information from logistics documents and output the result as a JSON object."
          },
          {
            role: "user",
            content: extract_invoice_prompt(text)
          }
        ],
        max_tokens: 3000
      }
    )
    choices = response.dig("choices")
    stringified = response.dig("choices", 0, "message", "content").strip
    prompt_record.output = choices.to_s
    prompt_record.save
    response = convert_to_json(stringified)
    response
  end

  def extract_invoice_with_document(text, file_path)
    model = "gpt-4o-mini"
    images = convert_to_images(file_path)

    messages = [
      {
        role: "system",
        content: "You are an AI assistant trained to extract invoice information from logistics documents and output the result as a JSON object."
      },
      {
        role: "user",
        content: [
          { type: "text", text: extract_invoice_with_document_prompt(text) },
          *images.map { |img| { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{img}" } } }
        ]
      }
    ]

    response = @client.chat(
      parameters: {
        model: model,
        messages: messages,
        max_tokens: 3000,
        response_format: { type: "json_object" }
      }
    )

    stringified = response.dig("choices", 0, "message", "content").strip

    convert_to_json(stringified)
  end

  def really_invoice?(text, file_path)
    model = "gpt-4o-mini"
    images = convert_to_images(file_path)

    prompt_record = Prompt.new(model: model, input: text, task_type: "really_invoice")
    messages = [
      {
        role: "system",
        content: "You are an AI assistant trained to determine if a document is an invoice. Please respond with 'true' if it is an invoice, and 'false' otherwise."
      },
      {
        role: "user",
        content: [
          { type: "text", text: "Is the following text/document an invoice? Sometimes we get references to invoices that are not actual invoices. Please respond with 'true' if it is an invoice, and 'false' otherwise. #{text}" },
          *images.map { |img| { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{img}" } } }
        ]
      }
    ]

    response = @client.chat(
      parameters: {
        model: model,
        messages: messages,
        max_tokens: 1000
      }
    )

    response.dig("choices", 0, "message", "content").strip
  end

  private
  def extract_prompt(text)
    prompt = <<-PROMPT
    Extract the following information from the provided text. Leave any field blank if the information is not present or cannot be determined accurately.

    Text:
    #{text}

    Sample Output format (JSON):
    {
      "origin_code": "USLAX",
      "origin_name": "Port of Los Angeles",
      "origin_iata": "LAX",
      "origin_address_1": "425 South Palos Verdes Street",
      "origin_address_2": "",
      "origin_postcode": "90731",
      "origin_city": "San Pedro",
      "origin_state_code": "CA",
      "origin_country_code": "USA",
      "destination_code": "USELP",
      "destination_name": "El Paso",
      "destination_iata": "ELP",
      "destination_address_1": "6701 Convair Rd",
      "destination_address_2": "",
      "destination_postcode": "79925",
      "destination_city": "El Paso",
      "destination_state_code": "TX",
      "destination_country_code": "USA",
      "transport_type": "AIR|COU|FAS|FSA|RAI|ROA|SEA",
      "container_type": "BCN|CON|LSE|SCN|ULD|BBK|BLK|FCL|LCL|LQD|ROR|FTL|LTL|OBC|UNA",
      "shipment_type": "STD|CLD|CLB|BCN|ASM|HVL|3PT|SCN",
      "shipper_code": "",
      "consignee_code": "",
      "customer_code": "",
      "weight": "<aggregate shipment weight>",
      "weight_units": "<determine from packing list>",
      "volume": "<determine from packing list>",
      "volume_units": "<determine from packing list>",
      "length": "<determine from packing list>",
      "width": "<determine from packing list>",
      "height": "<determine from packing list>",
      "measurement_units": "<determine from packing list>",
      "po_number": "<purchase order number>",
      "bol_number": "<bill of lading number>",
      "shipped_date": "<date shipped>",
      "issue_date": "<date issued>",
      "eta": "<estimated time of arrival>",
      "etd": "<estimated time of departure>",
      "description": "",
      "commodity_code": "",
      "initial_platform": "",
      "destination_platform": "",
      "platform_shipment_id": "",
      "platform_consol_id": "",
      "line_items": [<list of line items in JSON format if applicable>]
    }
    PROMPT
  end

  def extract_invoice_with_document_prompt(text)
    <<-PROMPT
    If the invoice includes shipping information, e.g. item dimensions, weights, part numbers,etc., set is_shipping_invoice to "true". Otherwise, set it to "false" unless you strongly believe it is an invoice for freight.

    Extract the following information from the provided invoice document. Leave any field blank if the information is not present or cannot be determined accurately.

    Additional Text:
    #{text}

    Output format (JSON):
    {
      "invoice_number": "",
      "house_bill_of_lading_number": "",
      "master_bill_of_lading_number": "",
      "order_number": "",
      "bill_to_name": "",
      "bill_to_address_1": "",
      "bill_to_address_2": "",
      "bill_to_city": "",
      "bill_to_state": "",
      "bill_to_postcode": "",
      "bill_to_country": "",
      "pay_to_name": "",
      "pay_to_address_1": "",
      "pay_to_address_2": "",
      "pay_to_city": "",
      "pay_to_state": "",
      "pay_to_postcode": "",
      "pay_to_country": "",
      "consignee_name": "",
      "consignee_address_1": "",
      "consignee_address_2": "",
      "consignee_city": "",
      "consignee_state": "",
      "consignee_postcode": "",
      "consignee_country": "",
      "total": "",
      "description": "",
      "payment_terms": "",
      "due_date": "",
      "issue_date": "",
      "order_number": "",
      "is_freight_invoice": "",
      "line_items": [
        {
          "description": "",
          "quantity": "",
          "value": "",
          "currency": "",
          "datetime": ""
        }
      ]
    }
    PROMPT
  end

  def convert_to_images(file_path)
    extension = File.extname(file_path).downcase
    case extension
    when ".pdf"
      convert_pdf_to_images(file_path)
    when ".xlsx", ".xls"
      convert_spreadsheet_to_images(file_path)
    else
      [Base64.strict_encode64(File.read(file_path))]
    end
  end

  def convert_pdf_to_images(file_path)
    images = []
    MiniMagick::Image.open(file_path) do |pdf|
      pdf.pages.each do |page|
        page.format "jpg"
        images << Base64.strict_encode64(page.to_blob)
      end
    end
    images
  end

  def convert_spreadsheet_to_images(file_path)
    temp_pdf = Tempfile.new(["spreadsheet", ".pdf"])
    system("libreoffice", "--headless", "--convert-to", "pdf", "--outdir", File.dirname(temp_pdf.path), file_path)
    images = convert_pdf_to_images(temp_pdf.path)
    temp_pdf.unlink
    images
  end
end