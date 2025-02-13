class CargowiseController < ApplicationController
  def create_shipment
    @shipment = Shipment.find(params[:shipment_id])
    result = EadaptorService.create_shipment(@shipment.attributes)

    gz = Zlib::GzipReader.new(StringIO.new(result.body))
    result = gz.read

    if result.is_a?(String)
      xml = Nokogiri::XML(result).root
      xml_h = xml_to_hash(xml)
      platform_key = xml_h.dig(:Data, :UniversalEvent, :Event, :DataContext, :DataSourceCollection, :DataSource, :Key)
      @shipment.platform_shipment_id = platform_key if platform_key.present?
    end

    @shipment.uploaded_to_platform_at = Time.now
    @shipment.save

    redirect_to shipment_path(@shipment), notice: "Shipment created successfully, linked to #{platform_key}"
  end

  private
  # TODO: Extract to service for use also with api controller
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
