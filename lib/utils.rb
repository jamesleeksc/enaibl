module Utils
  CHARACTER_VALUES = {
    'A' => 10, 'B' => 12, 'C' => 13, 'D' => 14, 'E' => 15,
    'F' => 16, 'G' => 17, 'H' => 18, 'I' => 19, 'J' => 20,
    'K' => 21, 'L' => 23, 'M' => 24, 'N' => 25, 'O' => 26,
    'P' => 27, 'Q' => 28, 'R' => 29, 'S' => 30, 'T' => 31,
    'U' => 32, 'V' => 34, 'W' => 35, 'X' => 36, 'Y' => 37,
    'Z' => 38
  }

  WEIGHTS = [1, 2, 4, 8, 5, 10, 9, 7, 3, 6]

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

  def container_check_digit(container_number)
    base_part = container_number[0, 10]

    sum = 0
    base_part.chars.each_with_index do |char, index|
      value = char =~ /\d/ ? char.to_i : CHARACTER_VALUES[char]
      sum += value * WEIGHTS[index]
    end

    remainder = sum % 11
    check_digit = remainder == 10 ? 0 : remainder

    check_digit
  end

  def valid_container_number?(container_number)
    return false if container_number.blank? || container_number.length < 10

    check_digit = container_check_digit(container_number)
    container_number[-1] == check_digit.to_s
  end

  def corrected_container_number(container_number)
    return container_number if valid_container_number?(container_number)
    return if container_number.length < 10
    short_container_number = container_number[0..9]
    check_digit = container_check_digit(short_container_number)
    short_container_number + check_digit.to_s
  end
end
