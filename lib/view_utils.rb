require 'action_view'

class ViewUtils
  extend ActionView::Helpers::NumberHelper

  def self.currency_format(value, unit = "$")
    valid_currency_marks = ["$", "€", "£", "¥", "₹"]

    unit = unit.to_s.strip

    if unit == "USD"
      unit = "$"
    elsif unit == "EUR"
      unit = "€"
    elsif unit == "GBP"
      unit = "£"
    elsif unit == "JPY"
      unit = "¥"
    elsif unit == "INR"
      unit = "₹"
    elsif valid_currency_marks.exclude?(unit)
      unit = "$"
    end

    value = value.to_s.gsub(unit, "") if valid_currency_marks.include?(unit)

    number_to_currency(value, unit: unit)
  end
end
