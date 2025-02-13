class InvoicesController < ApplicationController
  def index
    @documents = Document.all

    @documents = @documents.where(invoice: true) if params[:invoice] == "true"
    @documents = @documents.where(confirmed_invoice: true) if params[:confirmed] == "true"
    @documents = @documents.where(shipping_invoice: true) if params[:shipping] == "true"
    @documents = @documents.where(ap_or_ar: params[:ap_or_ar]) if params[:ap_or_ar].in?(%w[ap ar])

    @documents = @documents.order(created_at: :desc)
  end

  def show
    @document = Document.find(params[:id])
  end
end
