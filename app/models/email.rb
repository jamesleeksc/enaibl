class Email < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :client_account, optional: true
  has_and_belongs_to_many :shipments

  # classify after create
  after_create :classify

  # irrelevant scope
  scope :irrelevant, -> { where(irrelevant: true) }

  def self.categories(raw)
    begin
      sanitized = raw.gsub("```json", "").gsub("```", "").gsub("\n", "")
      return [] if sanitized.blank?
      result = JSON.parse(sanitized).select { |k, v| Utils.to_boolean(v) }.keys
    rescue JSON::ParserError
      result = []
    end
    result
  end

  def self.readable_categories(raw)
    categories = self.categories(raw)
    categories.map { |category| category.humanize.upcase }
  end

  def self.html_class(category)
    primary = ['carrier_quote_email', 'customer_quote_pdf', 'master_bill_of_lading', 'isf_transmission_pdf']
    success = ['customer_quote_confirmation_email', 'isf_excel', 'proof_of_delivery']
    warning = ['house_bill_of_lading', 'commercial_invoice', 'customs_clearance']
    secondary = ['packing_list']
    info = ['misc_relevant']
    light = ['irrelevant']

    if primary.any? { |word| category.include?(word) }
      return 'badge-primary'
    elsif success.any? { |word| category.include?(word) }
      return 'badge-success'
    elsif warning.any? { |word| category.include?(word) }
      return 'badge-warning'
    elsif secondary.any? { |word| category.include?(word) }
      return 'badge-secondary'
    elsif info.any? { |word| category.include?(word) }
      return 'badge-info'
    end

    'badge-light'
  end

  def classify
    # TODO: classify attachments also
    self.category = OpenAiService.new.classify_document("Subject: #{subject}\nMessage:#{body}")
    save
  end

  def categories
    Email.categories(category)
  end

  def readable_categories
    Email.readable_categories(category)
  end

  def html_categories
    categories.map do |category|
      "<span class='badge #{Email.html_class(category)}'>#{category.humanize.upcase}</span>"
    end.join(' ').html_safe
  end

  def owned_by?(user)
    self.user_id == user.id ||
    self.client_account_id != user.client_account_id
  end

  def process_documents

  end
end
