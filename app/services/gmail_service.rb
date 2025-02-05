# app/services/gmail_service.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class GmailService
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def initialize(authorization = nil, max_results: 10)
    @max_results = max_results
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorization
  end

  def list_messages
    user_id = 'me'
    result = @service.list_user_messages(user_id, max_results: @max_results)
    result.messages || []
  end

  def get_message(message_id)
    user_id = 'me'
    @service.get_user_message(user_id, message_id)
  end

  def extract_body(payload)
    if payload.parts
      payload.parts.each do |part|
        if part.mime_type == 'text/plain'
          return decode_base64(part.body.data) if part.body.data
        elsif part.mime_type == 'text/html'
          # Optionally handle HTML content
          # return decode_base64(part.body.data) if part.body.data
        elsif part.mime_type.start_with?('multipart/')
          result = extract_body(part) # Recursive call for nested multiparts
          return result if result.present?
        end
      end
    elsif payload.body && payload.body.data
      decode_base64(payload.body.data)
    else
      ""
    end
  end

  def fetch_email_raw(msg_id)
    begin
      msg = @service.get_user_message('me', msg_id, format: 'raw')
      msg_str = sanitize_base64(msg.raw)
      mime_msg = Mail.read_from_string(Base64.decode64(msg_str))
      mime_msg
    rescue Google::Apis::Error => e
      Rails.logger.error("An error occurred: #{e.message}")
      nil
    end
  end

  def list_threads
    user_id = 'me'
    result = @service.list_user_threads(user_id, max_results: @max_results)
    result.threads || []
  end

  def get_thread(thread_id)
    user_id = 'me'
    @service.get_user_thread(user_id, thread_id)
  end

  def get_gmail_messages(start_date: nil, max_results_per_page: 10, page_token: nil)
    query = ''
    query = "after:#{start_date.strftime('%Y/%m/%d')}" if start_date

    all_messages = []
    begin
      results = @service.list_user_messages('me', q: query, max_results: max_results_per_page, page_token: page_token)
      messages = results.messages || []
      all_messages.concat(messages)

      next_page_token = results.next_page_token
      result_size_estimate = results.result_size_estimate

      [all_messages, next_page_token, result_size_estimate]
    rescue Google::Apis::Error => e
      Rails.logger.error("An error occurred: #{e.message}")
      [[], nil, 0]
    end
  end

  # Fetch individual email by ID
  def fetch_email(msg_id)
    begin
      msg = @service.get_user_message('me', msg_id, format: 'full')
      msg
    rescue Google::Apis::Error => e
      Rails.logger.error("An error occurred: #{e.message}")
      nil
    end
  end

  # Extract the email body from the MIME message
  def get_email_body(msg)
    extract_body(msg.payload)
  end

  # Parse each part of the message payload
  def extract_body(payload)
    body = ""

    if payload.parts
      payload.parts.each do |part|
        content_type = part.mime_type
        if content_type.start_with?('multipart/')
          # Recursive call for nested multiparts
          nested_body = extract_body(part)
          body += nested_body if nested_body.present?
        elsif content_type == 'text/plain'
          body += part.body.data if part.body.data
        elsif content_type == 'text/html'
          # Optionally handle HTML content
          # body += decode_base64(part.body.data) if part.body.data
        end
      end
    elsif payload.body && payload.body.data
      body = decode_base64(payload.body.data)
    end

    body
  end

  # Decode base64 content safely
  def decode_base64(data)
    sanitized_data = sanitize_base64(data)
    Base64.urlsafe_decode64(sanitized_data)
  rescue ArgumentError => e
    Rails.logger.error("Failed to decode email body: #{e.message}")
    ""
  end

  # Sanitize the base64 string by removing unwanted characters
  def sanitize_base64(data)
    data.tr("\n", '').tr('_-', '+/')
  end

  def parse_message(message)
    headers = message.payload.headers
    {
      from: headers.find { |h| h.name == 'From' }&.value,
      to: headers.find { |h| h.name == 'To' }&.value,
      subject: headers.find { |h| h.name == 'Subject' }&.value,
      date: headers.find { |h| h.name == 'Date' }&.value,
      body: extract_body(message.payload)
    }
  end

  private

  def authorize
    client_id = Rails.application.credentials.dig(:gmail, :client_id)
    client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
    redirect_uri = ENV['REDIRECT_URI']

    client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      return false
      # url = authorizer.get_authorization_url(base_url: redirect_uri)
      # # Handle in UI
      # puts "Open the following URL in the browser and enter the " \
      #      "resulting code after authorization:\n" + url
      # code = gets.chomp
      # credentials = authorizer.get_and_store_credentials_from_code(
      #   user_id: user_id, code: code, base_url: redirect_uri
      # )
    end
    credentials
  end

  def decode_base64(data)
    Base64.urlsafe_decode64(data)
  rescue ArgumentError => e
    Rails.logger.error("Failed to decode email body: #{e.message}")
    ""
  end

  def sanitize_base64(data)
    data.tr("\n", '').tr('_-', '+/')
  end
end
