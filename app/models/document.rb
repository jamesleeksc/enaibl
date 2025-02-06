class Document < ApplicationRecord
  belongs_to :email, optional: true
  belongs_to :client_account, optional: true
  belongs_to :user, optional: true

  has_one_attached :file
  after_commit :extract_text

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
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      text = extract_text_from_docx(file_path)
    when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      text = extract_text_from_spreadsheet(file_path)
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
      text += page.text
    end

    text
  end

  def ocr_on_pdf(file_path)
    images = MiniMagick::Image.read(File.open(file_path))
    texts = []
    # Iterate over each page
    images.pages.each_with_index do |page, index|
      page_path = "/tmp/page_#{index}.png"
      page.write(page_path) # Convert the page to an image

      # Run OCR using Tesseract
      ocr = RTesseract.new(page_path)
      extracted_text = ocr.to_s
      texts << extracted_text
    end

    texts
  end

  def ocr_box_on_pdf(file_path)
    images = MiniMagick::Image.read(File.open(file_path))
    texts = []
    # Iterate over each page
    images.pages.each_with_index do |page, index|
      page_path = "/tmp/page_#{index}.png"
      page.write(page_path) # Convert the page to an image

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

  private
  def ready_for_extract?
    file.attached? && content.blank? && file.blob.persisted?
  end
end
