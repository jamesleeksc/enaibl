module CvUtils
  def self.skew_angle(image_path)
    begin
      cmd = "python3 #{Rails.root}/lib/python/skew.py #{image_path}"
      output, _status = Open3.capture2(cmd)
      output.strip.to_f
    rescue => e
      Rails.logger.error("Error computing skew: #{e.message}")
      puts "Error computing skew: #{e.message}"
      puts "Have you set venv to enaiblrails?"
      0
    end
  end

  def self.derotate(image_path)
    angle = skew_angle(image_path)
    # derotate with imagemagick
    system("convert", image_path, "-rotate", "-#{angle}", image_path)
  end
end
