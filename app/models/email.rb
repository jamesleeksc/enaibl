class Email < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :client_account, optional: true
  has_and_belongs_to_many :shipments
  has_many :documents

  after_create :classify
  after_create :mark_relevance
  # TODO: Mark actionable

  scope :irrelevant, -> { where(irrelevant: true) }

  def self.categories(raw)
    return [] if raw.blank?
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

  def mark_relevance
    self.irrelevant = true if self.categories.include?('irrelevant')
    save if self.changed?
  end

  def classify
    self.category = OpenAiService.new.classify_document("Subject: #{subject}\nMessage:#{body}")
    save
  end

  def classify_pod
    return unless content.present?
    classification = OpenAiService.new.pod?(content)
    update(pod: classification)
  end

  def self.classify_all_pod
    Email.where(pod: nil).each do |email|
      email.classify_pod
    end
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

  def content
    "to: #{to}\nfrom: #{from}\nsubject: #{subject}\nbody: #{body}"
  end

  def invoice_category?
    categories.include?("commercial_invoice") || categories.include?("shipping_invoice") || categories.include?("other_invoice")
  end
end
