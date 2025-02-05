class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def eadaptor
    puts 'adaptor inbound'
    raw = request.body.read
    parsed_xml = Nokogiri::XML(raw)

    namespaces = {
      's' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'h' => 'http://CargoWise.com/eHub/2010/06',
      'o' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
    }

    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    raw_filename = "eadaptor_#{timestamp}.xml"

    File.write(raw_filename, raw)

    begin
      # Extract the Base64 encoded and compressed contents of the <Message> node
      encoded_data = parsed_xml.xpath('//s:Body/h:SendStreamRequest/h:Payload/h:Message', namespaces)
      total = encoded_data.size

      encoded_data.each_with_index do |datum, idx|
        decode_and_write(datum.text, timestamp, parsed_xml, idx, total)
      end
    rescue => e
      puts e.message
      msg = "Error[#{timestamp}]: #{e.message}"
      File.open('log/eadaptor.log', 'a') { |f| f.write(msg) }
    end

    # puts 'end'
    # head :ok
    # return xml type response
    render xml: soap_response, content_type: 'text/xml'
  end

  private

  def soap_response
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['s'].Envelope('xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/',
                        'xmlns:u' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd') do
        xml['s'].Header do
          xml['o'].Security('s:mustUnderstand' => '1', 'xmlns:o' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd') do
            xml['u'].Timestamp('u:Id' => '_0') do
              xml['u'].Created Time.now.utc.iso8601
              xml['u'].Expires (Time.now + 5.minutes).utc.iso8601
            end
          end
        end
        xml['s'].Body
      end
    end
    builder.to_xml
  end

  def decode_and_write(datum, timestamp, parsed_xml, idx = 0, total = 1)
    # Decode the Base64 string
    decoded_data = Base64.decode64(datum)

    # Decompress the GZIP data
    gzip = Zlib::GzipReader.new(StringIO.new(decoded_data))
    decompressed_data = gzip.read
    gzip.close

    # Parse the decompressed XML
    parsed_children_xml = Nokogiri::XML(decompressed_data)
    xml_hash = xml_to_hash(parsed_xml.root)
    body_hash = xml_to_hash(parsed_children_xml.root)

    xml_hash[:Body][:SendStreamRequest][:Payload][:Message] = body_hash

    # Convert Hash to JSON
    json_data = JSON.pretty_generate(xml_hash)

    # Save JSON to a file
    File.write("output#{timestamp}-#{idx+1}of#{total}.json", json_data)
  end

  def xml_to_hash(node)
    if node.element?
      result_hash = {}
      node.attributes.each do |key, attr|
        result_hash[attr.name.to_sym] = attr.value
      end
      node.children.each do |child|
        result = xml_to_hash(child)
        if child.name == "text"
          unless child.next_sibling || child.previous_sibling
            return result
          end
        elsif result_hash[child.name.to_sym]
          if result_hash[child.name.to_sym].is_a?(Array)
            result_hash[child.name.to_sym] << result
          else
            result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << result
          end
        else
          result_hash[child.name.to_sym] = result
        end
      end
      return result_hash
    else
      return node.content.to_s
    end
  end
end
