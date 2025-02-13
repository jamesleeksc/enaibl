class Document < ApplicationRecord
  belongs_to :email, optional: true
  belongs_to :client_account, optional: true
  belongs_to :user, optional: true

  has_one_attached :file
  # TODO: extract and classify in a job after create
  after_commit :extract_text
  after_save :classify_changes

  scope :invoice, -> { where(invoice: true) }
  scope :ap, -> { where(invoice: true, ap_or_ar: "ap") }
  scope :ar, -> { where(invoice: true, ap_or_ar: "ar") }
  scope :confirmed_invoice, -> { where(confirmed_invoice: true) }
  scope :ciap, -> { where(confirmed_invoice: true, ap_or_ar: "ap") }
  scope :ciar, -> { where(confirmed_invoice: true, ap_or_ar: "ar") }
  scope :sciap, -> { where(confirmed_invoice: true, ap_or_ar: "ap", shipping_invoice: true) }
  scope :sciar, -> { where(confirmed_invoice: true, ap_or_ar: "ar", shipping_invoice: true) }

  def self.classify_new!
    Document.where.not(content: nil).where(category: nil).each do |document|
      document.classify
    end
  end

  def local_copy
    return unless file.attached?
    return unless file.blob.persisted?
    attachment_path = "#{Dir.tmpdir}/#{file.filename}"

    File.open(attachment_path, 'wb') do |attachment|
      file_content = File.open(ActiveStorage::Blob.service.path_for(file.key), "rb") { |f| f.read }
      attachment.write(file_content)
    end

    attachment_path
  end

  def extract_text
    return unless ready_for_extract?
    file_path = local_copy

    text = ""
    return "" unless file_path
    case file.content_type
    when "application/pdf"
      text = extract_text_from_pdf(file_path)
    when "image/jpeg", "image/png"
      text = extract_text_from_image(file_path)
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document" || "application/msword"
      text = extract_text_from_docx(file_path)
    when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || "application/vnd.ms-excel"
      text = extract_text_from_spreadsheet(file_path)
      # text/html message/rfc822
    else
      return ""
    end

    assign_attributes(content: text)

    if text.present? && will_save_change_to_content?
      save
    end
  end

  def extract_text_from_pdf(file_path)
    reader = PDF::Reader.new(file_path)
    text = ""

    reader.pages.each do |page|
      begin
        p_text = page.text
      rescue => e
        puts "PDF read error: #{e.message}"
      end

      p_text = ocr_on_pdf(file_path).strip if p_text.blank?

      text += p_text
    end

    text
  end

  def ocr_on_pdf(file_path)
    texts = []

    begin
      images = MiniMagick::Image.read(File.open(file_path))
      images.pages.each_with_index do |page, index|
        page_path = File.join(Dir.tmpdir, "page_#{index}.png")
        page.write(page_path)

        if File.exist?(page_path)
          ocr = RTesseract.new(page_path)
          extracted_text = ocr.to_s
          texts << extracted_text
        else
          Rails.logger.error("OCR failed: Image file not found at #{page_path}")
        end

        File.delete(page_path) if File.exist?(page_path)
      end
    rescue => e
      Rails.logger.error("OCR failed: #{e.message}")
      texts << ""
    end

    texts.join("\n\n")
  end

  def ocr_box_on_pdf(file_path)
    images = MiniMagick::Image.read(File.open(file_path))
    texts = []

    images.pages.each_with_index do |page, index|
      page_path = "/tmp/page_#{index}.png"
      page.write(page_path)

      # Run OCR using Tesseract
      ocr = RTesseract.new(page_path)
      extracted_text = ocr.to_box
      texts << extracted_text
    end

    texts
  end

  def extract_text_from_image(file_path)
    ocr = RTesseract.new(file_path)
    ocr.to_s
  end

  def extract_box_from_image(file_path)
    ocr = RTesseract.new(file_path)
    ocr.to_box
  end

  def extract_text_from_docx(file_path)
    doc = Docx::Document.open(file_path)
    text = ""

    doc.paragraphs.each do |paragraph|
      text += paragraph.text
    end

    text
  end

  def extract_text_from_spreadsheet(file_path)
    sheet = Roo::Spreadsheet.open(file_path)
    text = ""

    sheet.each do |row|
      text += row.join(" ")
    end

    text
  end

  def classify
    return unless content.present?
    classification = OpenAiService.new.classify_document(content)
    update(category: classification)

    if categories.include?("commercial_invoice") || categories.include?("shipping_invoice") || categories.include?("other_invoice")
      classify_invoice
    end
  end

  def categories
    return [] unless category.present?
    Email.categories(category)
  end

  def readable_categories
    Email.readable_categories(category)
  end

  def classify_pod
    return unless content.present?
    classification = true if categories.include?("proof_of_delivery")
    classification ||= OpenAiService.new.pod?(content)
    update(pod: classification)
  end

  def classify_invoice
    confirmed_invoice = Utils.to_boolean(OpenAiService.new.really_invoice?(content, local_copy))
    assign_attributes(confirmed_invoice: confirmed_invoice)

    invoice_info = OpenAiService.new.extract_invoice_with_document(content, local_copy)

    assign_apar(invoice_info)

    if ap_or_ar.present? && invoice_info["is_freight_invoice"].present?
      shipping_inv = Utils.to_boolean(invoice_info["is_freight_invoice"])
    else
      shipping_inv = false
    end

    assign_attributes(invoice_content: invoice_info, shipping_invoice: shipping_inv, invoice: true)
    save
  end

  def assign_apar(invoice_info = {})
    assign_attributes(ap_or_ar: nil)

    if org_names.any? { |o_name| same_org?(o_name, invoice_info["pay_to_name"]) }
      assign_attributes(ap_or_ar: "ar")
    elsif org_names.any? { |o_name| same_org?(o_name, invoice_info["bill_to_name"]) }
      assign_attributes(ap_or_ar: "ap")
    end
  end

  def correct_apar
    assign_apar(invoice_content)
    save
  end

  def self.classify_all_pod
    Document.where(pod: nil).each do |document|
      document.classify_pod
    end
  end

  def html_categories
    categories.map do |category|
      "<span class='badge #{Email.html_class(category)}'>#{category.humanize.upcase}</span>"
    end.join(' ').html_safe
  end

  def self.classify_all_invoices
    Document.all.map do |d|
      next if d.invoice_content.present?
      if d.categories.include?("commercial_invoice") || d.categories.include?("shipping_invoice") || d.categories.include?("other_invoice")
        d.classify_invoice
      end
    end
  end

  def cw_shipment_number
    shipment_number = nil
    prefix = "S#{account_prefix}"

    if invoice_content.present?
      candidates = [
        invoice_content["house_bill_of_lading_number"],
        invoice_content["master_bill_of_lading_number"],
        invoice_content["order_number"]
      ].compact_blank

      shipment_number = candidates.find { |c| c.start_with?(prefix) }
      shipment_number ||= invoice_content.to_s.match(/#{prefix}\d+/)
      shipment_number = shipment_number[0] if shipment_number.is_a?(MatchData)
    end

    shipment_number ||= content.match(/#{prefix}\d+/)
    shipment_number = shipment_number[0] if shipment_number.is_a?(MatchData)

    shipment_number
  end

  def self.with_shipment_number(user)
    prefix = "S#{user.client_account&.branch_shortcode}"
    Document.where("invoice_content->>'house_bill_of_lading_number' LIKE ?", "%#{prefix}%").or(
    Document.where("invoice_content->>'master_bill_of_lading_number' LIKE ?", "%#{prefix}%")).or(
    Document.where("invoice_content->>'order_number' LIKE ?", "%#{prefix}%"))
  end

  def self.all_with_shipment_number(user)
    prefix = "S#{user.client_account&.branch_shortcode}"
    Document.where("invoice_content->>'house_bill_of_lading_number' LIKE ?", "%#{prefix}%").or(
    Document.where("invoice_content->>'master_bill_of_lading_number' LIKE ?", "%#{prefix}%")).or(
    Document.where("invoice_content->>'order_number' LIKE ?", "%#{prefix}%")).or(
    Document.where("content LIKE ?", "%#{prefix}%"))
  end

  def account_prefix
    client_account.branch_shortcode || user.client_account.branch_shortcode
  end

  private
  def classify_changes
    return unless content.present?
    return unless saved_change_to_content?
    classification = OpenAiService.new.classify_document(content)
    update(category: classification)
    if categories.include?("commercial_invoice") || categories.include?("shipping_invoice") || categories.include?("other_invoice")
      classify_invoice
    end
  end

  def mark_relevance
    self.irrelevant = true if self.categories.include?('irrelevant')
    save if self.changed?
  end

  def ready_for_extract?
    file.attached? && content.blank? && file.blob.persisted?
  end

  def levenshtein_distance(str1, str2)
    m, n = str1.length, str2.length
    return n if m == 0
    return m if n == 0

    d = Array.new(m+1) {Array.new(n+1)}

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..m).each do |i|
      (1..n).each do |j|
        d[i][j] = if str1[i-1] == str2[j-1]
                    d[i-1][j-1]
                  else
                    [d[i-1][j], d[i][j-1], d[i-1][j-1]].min + 1
                  end
      end
    end

    d[m][n]
  end

  def same_org?(str1, str2)
    org1 = str1.gsub(/[^A-Za-z0-9]/, '').downcase
    org2 = str2.gsub(/[^A-Za-z0-9]/, '').downcase

    levenshtein_distance(org1, org2) <= 3
  end

  def org_names
    accts = [client_account] + [user&.client_account]
    accts = accts.uniq.compact

    org_names = []

    accts.each do |a|
      org_names << a.full_name
      a.alias_organizations.split("\n").each do |alias_name|
        org_names << alias_name
      end
    end

    org_names
  end
end
