module ApplicationHelper
  def file_icon(filename)
    extension = File.extname(filename).downcase
    case extension
    when '.pdf'
      '<i class="far fa-file-pdf text-danger"></i>'.html_safe
    when '.xlsx', '.xls'
      '<i class="far fa-file-excel text-success"></i>'.html_safe
    when '.docx', '.doc'
      '<i class="far fa-file-word text-primary"></i>'.html_safe
    else
      '<i class="far fa-file text-secondary"></i>'.html_safe
    end
  end
end
