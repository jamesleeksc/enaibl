class Container
  has_many :document_containers
  has_many :documents, through: :document_containers
  # NOTE: may want to reference with shipment and email as well
  #       may want to track origin/destination/location
end
