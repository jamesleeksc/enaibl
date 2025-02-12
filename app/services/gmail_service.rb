# app/services/gmail_service.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class GmailService
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def initialize(user:, authorization: nil, max_results: 10, start_date: nil)
    return unless user
    @start_date = start_date
    @max_results = max_results
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorization
  end

  def list_messages
    user_id = 'me'
    start_query = "after:#{@start_date.strftime('%Y/%m/%d')}" if @start_date
    result = @service.list_user_messages(user_id, max_results: @max_results, q: start_query)
    result.messages || []
  end

  def get_message(message_id)
    user_id = 'me'
    @service.get_user_message(user_id, message_id)
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

  def extract_body_and_attachments(payload, msg_id)
    body = ""
    attachments = []

    if payload.parts
      payload.parts.each do |part|
        content_type = part.mime_type

        if content_type.start_with?('multipart/')
          # Recursive call for nested multiparts
          nested_body, nested_attachments = extract_body_and_attachments(part, msg_id)
          body += nested_body if nested_body.present?
          attachments.concat(nested_attachments) if nested_attachments.any?
        elsif content_type == 'text/plain'
          body += decode_base64(part.body.data) if part.body.data
        elsif content_type == 'text/html'
          # Optionally handle HTML content
          # body += decode_base64(part.body.data) if part.body.data
        elsif content_type == 'application/octet-stream'
          # Handle generic binary data
          attachment_data = part.body.data || fetch_attachment_data(part, msg_id)
          attachments << {
            filename: part.filename || "attachment_#{msg_id}",
            mime_type: content_type,
            data: StringIO.new(attachment_data)
          }
        elsif part.filename.present? # Check if it's an attachment
          attachment_data = part.body.data || fetch_attachment_data(part, msg_id)
          attachments << {
            filename: part.filename,
            mime_type: content_type,
            data: StringIO.new(attachment_data)
          }
        end
      end
    elsif payload.body && payload.body.data
      body = decode_base64(payload.body.data)
    end

    [body, attachments]
  end

  def fetch_attachment_data(part, msg_id)
    attachment_id = part.body.attachment_id
    return unless attachment_id

    attachment = @service.get_user_message_attachment('me', msg_id, attachment_id)
    attachment.data
  end

  # Decode base64 content safely
  def decode_base64(data)
    sanitized_data = sanitize_base64(data)
    Base64.urlsafe_decode64(sanitized_data)
  rescue ArgumentError => e
    Rails.logger.error("Failed to decode email body: #{e.message}")
    ""
  end

  def parse_message(message)
    body, attachments = extract_body_and_attachments(message.payload, message.id)
    headers = message.payload.headers
    {
      from: headers.find { |h| h.name == 'From' }&.value,
      to: headers.find { |h| h.name == 'To' }&.value,
      subject: headers.find { |h| h.name == 'Subject' }&.value,
      date: headers.find { |h| h.name == 'Date' }&.value,
      body: body,
      attachments: attachments
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
      # NOTE: Handled in email_controller
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
