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
end
