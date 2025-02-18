class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def index
    @documents = current_user.all_documents.invoice

    params[:confirmed] ||= "true"
    params[:shipping] ||= "true"
    params[:ap_or_ar] ||= "ap"

    @documents = @documents.where(confirmed_invoice: true) if params[:confirmed] == "true"
    @documents = @documents.where(shipping_invoice: Utils.to_boolean(params[:shipping])) if params[:shipping].in?(%w[true false])
    @documents = @documents.where(ap_or_ar: params[:ap_or_ar]) if params[:ap_or_ar].in?(%w[ap ar])
    @documents = @documents.all_with_shipment_number(current_user) if params[:has_shipment_no] == "true"

    if params[:search].present?
      @documents = @documents.where("invoice_content::text ILIKE :search OR content::text ILIKE :search", search: "%#{params[:search]}%")
    end

    @documents = @documents.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.turbo_stream { render partial: 'invoices', locals: { documents: @documents } }
    end
  end

  def show
    @document = Document.find(params[:id])
  end

  def export
    @documents = current_user.all_documents.invoice

    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Invoices") do |sheet|
      headers = ['Invoice Number', 'Date', 'Total Amount', 'Vendor', 'Item Description', 'Quantity', 'Unit Price', 'Total Price']
      sheet.add_row headers

      @documents.each do |document|
        document.invoice_content['line_items'].each do |item|
          sheet.add_row [
            document.invoice_content['invoice_number'],
            document.invoice_content['issue_date'],
            document.invoice_content['total'],
            document.invoice_content['pay_to_name'],
            item["description"],
            item["quantity"],
            item["unit_price"],
            item["value"]
          ]
        end
      end
    end

    send_data package.to_stream.read,
    filename: "invoices_export_#{Time.current.strftime('%Y%m%d%H%M%S')}.xlsx",
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
end
