module Utils
  def self.to_boolean(value)
    normalized_value = value.to_s.downcase.strip
    true_values = ['true', 't', 'yes', 'y', '1', 'on']
    false_values = ['false', 'f', 'no', 'n', '0', 'off']

    if true_values.include?(normalized_value)
      true
    elsif false_values.include?(normalized_value)
      false
    else
      nil
    end
  end
end
