class EadaptorService
  EADAPTOR_URL = Rails.application.credentials.eadaptor_inbound[:url]
  USER = Rails.application.credentials.eadaptor_inbound[:user]
  PASSWORD = Rails.application.credentials.eadaptor_inbound[:password]

  def self.eadaptor_request(data)
    uri = URI.parse(EADAPTOR_URL)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(USER, PASSWORD)
    request.content_type = 'application/xml'
    request['Accept-Encoding'] = 'gzip, deflate'
    request.body = data

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      puts "Response received:"
      if response['Content-Encoding'].to_s.downcase.include?('gzip')
        begin
          gz = Zlib::GzipReader.new(StringIO.new(response.body))
          puts gz.read
        rescue Zlib::GzipFile::Error
          puts "Received response is not a valid gzip file. Displaying as plain text:"
          puts response.body
        end
      else
        puts response.body
      end
    else
      puts "Error: #{response.code} - #{response.message}"
    end
  end

  def self.shipment_by_key(shipment_key)
    data = <<~XML
      <UniversalShipmentRequest xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
        <ShipmentRequest>
          <DataContext>
            <DataTargetCollection>
              <DataTarget>
                <Type>ForwardingShipment</Type>
                <Key>#{shipment_key}</Key>
              </DataTarget>
            </DataTargetCollection>
          </DataContext>
        </ShipmentRequest>
      </UniversalShipmentRequest>
    XML
    eadaptor_request(data)
  end

  def self.org_by_name(org_name)
    data = <<~XML
      <Native xmlns="http://www.cargowise.com/Schemas/Native">
        <Body>
          <Organization>
            <CriteriaGroup Type="Partial">
              <Criteria Entity="OrgHeader" FieldName="FullName">
                #{org_name}%
              </Criteria>
            </CriteriaGroup>
          </Organization>
        </Body>
      </Native>
    XML
    eadaptor_request(data)
  end

  def self.forwarder_by_name(forwarder_name)
    data = <<~XML
      <Native xmlns="http://www.cargowise.com/Schemas/Native">
        <Body>
          <Organization>
            <CriteriaGroup Type="Partial">
              <Criteria Entity="OrgHeader" FieldName="FullName">
                #{forwarder_name}%
              </Criteria>
              <Criteria Entity="OrgHeader" FieldName="IsForwarder">
                True
              </Criteria>
            </CriteriaGroup>
          </Organization>
        </Body>
      </Native>
    XML
    eadaptor_request(data)
  end

  def self.shipping_provider_by_name(provider_name)
    data = <<~XML
      <Native xmlns="http://www.cargowise.com/Schemas/Native">
        <Body>
          <Organization>
            <CriteriaGroup Type="Partial">
              <Criteria Entity="OrgHeader" FieldName="FullName">
                #{provider_name}%
              </Criteria>
              <Criteria Entity="OrgHeader" FieldName="IsShippingProvider">
                True
              </Criteria>
            </CriteriaGroup>
          </Organization>
        </Body>
      </Native>
    XML
    eadaptor_request(data)
  end

  def self.consignee_by_name(name)
    data = <<~XML
      <Native xmlns="http://www.cargowise.com/Schemas/Native">
        <Body>
          <Organization>
            <CriteriaGroup Type="Partial">
              <Criteria Entity="OrgHeader" FieldName="FullName">
                #{name}%
              </Criteria>
              <Criteria Entity="OrgHeader" FieldName="IsConsignee">
                True
              </Criteria>
            </CriteriaGroup>
          </Organization>
        </Body>
      </Native>
    XML
    eadaptor_request(data)
  end

  def self.create_shipment(shipment_data)
    puts "Creating shipment with data: #{shipment_data.inspect}"
    description = shipment_data[:description]
    transport_mode = shipment_data[:transport_mode]
    transport_mode ||= "ROA"

    transport_modes = {
      "AIR" => "Air Freight",
      "COU" => "Courier",
      "FAS" => "First by Air then by Sea Freight",
      "FSA" => "First by Sea then by Air Freight",
      "RAI" => "Rail Freight",
      "ROA" => "Road Freight",
      "SEA" => "Sea Freight",
    }

    air_container_modes = {
      "BCN" => "Buyer's Consolidation",
      "CON" => "Agent Consolidation",
      "LSE" => "Loose",
      "SCN" => "Shipper's Consolidation",
      "ULD" => "Unit Load Device",
    }

    sea_container_modes = {
      "BBK" => "Break Bulk",
      "BCN" => "Buyer's Consolidation",
      "BLK" => "Bulk",
      "FCL" => "Full Container Load",
      "LCL" => "Less Container Load",
      "LQD" => "Liquid",
      "ROR" => "Roll On/Roll Off",
      "SCN" => "Shipper's Consolidation",
    }

    multimodal_container_modes = {
      "LCL" => "Less Container Load",
      "LSE" => "Loose",
      "ULD" => "Unit Load Device",
    }

    road_container_modes = {
      "BCN" => "Buyer's Consolidation",
      "FTL" => "Full Truck Load",
      "LCL" => "Less Container Load",
      "LTL" => "Less Truck Load",
      "SCN" => "Shipper's Consolidation",
    }

    courier_container_modes = {
      "OBC" => "On Board Courier",
      "UNA" => "Unaccompanied",
    }

    container_modes = {
      "BBK" => "Break Bulk",
      "BCN" => "Buyer's Consolidation",
      "BLK" => "Bulk",
      "CON" => "Agent Consolidation",
      "FCL" => "Full Container Load",
      "FTL" => "Full Truck Load",
      "LCL" => "Less Container Load",
      "LSE" => "Loose",
      "LTL" => "Less than Truck Load",
      "LQD" => "Liquid",
      "OBC" => "On Board Courier",
      "ROR" => "Roll On/Roll Off",
      "SCN" => "Shipper's Consolidation",
      "ULD" => "Unit Load Device",
      "UNA" => "Unaccompanied",
    }

    type_modes = {
      "STD" => "Standard House",
      "CLD" => "Co-Load Master",
      "CLB" => "Blind Co-Load Master",
      "BCN" => "Buyer's Consol Lead",
      "ASM" => "Assembly Master",
      "HVL" => "HVL Shipper Consolidation",
      "3PT" => "Third Party Ownership House",
      "SCN" => "Shipper's Consol Lead"
    }

    type_mode = shipment_data[:type_mode]
    type_mode ||= "STD"
    type_description = type_modes[type_mode]

    container_mode = shipment_data[:container_mode]
    container_mode ||= "LSE"
    mode_description = container_modes[container_mode]

    # WIP: ADD standard address fields, weights, documents
    data = <<~XML
      <UniversalShipment xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
        <Shipment>
          <DataContext>
            <DataTargetCollection>
              <DataTarget>
                <Type>ForwardingShipment</Type>
              </DataTarget>
            </DataTargetCollection>
          </DataContext>
          <ContainerMode>
            <Code>#{container_mode}</Code>
            <Description>#{mode_description}</Description>
          </ContainerMode>
          <GoodsDescription>#{description}</GoodsDescription>
          <OuterPacks>2</OuterPacks>
          <OuterPacksPackageType>
            <Code>PKG</Code>
            <Description>Package</Description>
          </OuterPacksPackageType>
          <PortOfDestination>
            <Code>AUSYD</Code>
            <Name>Sydney</Name>
          </PortOfDestination>
          <PortOfOrigin>
            <Code>USLAX</Code>
            <Name>Los Angeles</Name>
          </PortOfOrigin>
          <ReleaseType>
            <Code>EBL</Code>
            <Description>Express Bill of Lading</Description>
          </ReleaseType>
          <ServiceLevel>
            <Code>STD</Code>
            <Description>Standard Service</Description>
          </ServiceLevel>
          <ShipmentType>
            <Code>STD</Code>
            <Description>Standard House</Description>
          </ShipmentType>
          <TotalVolume>1.78</TotalVolume>
          <TotalVolumeUnit>
            <Code>M3</Code>
            <Description>Cubic Metres</Description>
          </TotalVolumeUnit>
          <TotalWeight>156</TotalWeight>
          <TotalWeightUnit>
            <Code>KG</Code>
            <Description>Kilograms</Description>
          </TotalWeightUnit>
          <TransportMode>
            <Code>AIR</Code>
            <Description>Air Freight</Description>
          </TransportMode>
          <VoyageFlightNo>QF12</VoyageFlightNo>
          <WayBillNumber>SYD0143AUSYD7Q</WayBillNumber>
          <WayBillType>
            <Code>HWB</Code>
            <Description>House Waybill</Description>
          </WayBillType>

          <DateCollection>
            <Date>
              <Type>Departure</Type>
              <IsEstimate>true</IsEstimate>
              <Value>2017-09-20T00:00:00</Value>
            </Date>
            <Date>
              <Type>Arrival</Type>
              <IsEstimate>true</IsEstimate>
              <Value>2017-09-20T00:00:00</Value>
            </Date>
          </DateCollection>

          <OrganizationAddressCollection>
            <OrganizationAddress>
              <AddressType>ConsignorDocumentaryAddress</AddressType>
              <Address1>1 long rd</Address1>
              <Address2></Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>1 long rd</AddressShortCode>
              <City>Los Angeles</City>
              <CompanyName>etailer los angeles</CompanyName>
              <Country>
                <Code>US</Code>
                <Name>United States</Name>
              </Country>
              <Email></Email>
              <Fax></Fax>
              <OrganizationCode>ETAILELAX</OrganizationCode>
              <Phone></Phone>
              <Port>
                <Code>USLAX</Code>
                <Name>Los Angeles</Name>
              </Port>
              <Postcode>90210</Postcode>
              <State>CA</State>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>ConsignorPickupDeliveryAddress</AddressType>
              <Address1>1 long rd</Address1>
              <Address2></Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>1 long rd</AddressShortCode>
              <City>Los Angeles</City>
              <CompanyName>etailer los angeles</CompanyName>
              <Country>
                <Code>US</Code>
                <Name>United States</Name>
              </Country>
              <Email></Email>
              <Fax></Fax>
              <OrganizationCode>ETAILELAX</OrganizationCode>
              <Phone></Phone>
              <Port>
                <Code>USLAX</Code>
                <Name>Los Angeles</Name>
              </Port>
              <Postcode>90210</Postcode>
              <State>CA</State>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>ConsigneeDocumentaryAddress</AddressType>
              <Address1>7 FIRST STREET</Address1>
              <Address2></Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>7 FIRST STREET</AddressShortCode>
              <City>KINGSWOOD</City>
              <CompanyName>AU 1 IMPORTER/EXPORTER CORPORATION</CompanyName>
              <Contact>Operations</Contact>
              <Country>
                <Code>AU</Code>
                <Name>Australia</Name>
              </Country>
              <Email>operations.ausyd@client.com</Email>
              <Fax>+61285231223</Fax>
              <GovRegNum>23132835888</GovRegNum>
              <GovRegNumType>
                <Code>ABN</Code>
                <Description>Australian Business Number (GST Reg</Description>
              </GovRegNumType>
              <Mobile></Mobile>
              <OrganizationCode>AU1IMPSYD</OrganizationCode>
              <Phone>+61285231212</Phone>
              <Port>
                <Code>AUSYD</Code>
                <Name>Sydney</Name>
              </Port>
              <Postcode>2747</Postcode>
              <State>NSW</State>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>ConsigneePickupDeliveryAddress</AddressType>
              <Address1>7 FIRST STREET</Address1>
              <Address2></Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>7 FIRST STREET</AddressShortCode>
              <City>KINGSWOOD</City>
              <CompanyName>AU 1 IMPORTER/EXPORTER CORPORATION</CompanyName>
              <Country>
                <Code>AU</Code>
                <Name>Australia</Name>
              </Country>
              <Email>main.ausyd@au1importerexporter.com</Email>
              <Fax>+61285231223</Fax>
              <GovRegNum>23132835888</GovRegNum>
              <GovRegNumType>
                <Code>ABN</Code>
                <Description>Australian Business Number (GST Reg</Description>
              </GovRegNumType>
              <OrganizationCode>AU1IMPSYD</OrganizationCode>
              <Phone>+61285231212</Phone>
              <Port>
                <Code>AUSYD</Code>
                <Name>Sydney</Name>
              </Port>
              <Postcode>2747</Postcode>
              <State>NSW</State>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>SendersLocalClient</AddressType>
              <Address1>7 FIRST STREET</Address1>
              <Address2></Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>7 FIRST STREET</AddressShortCode>
              <City>KINGSWOOD</City>
              <CompanyName>AU 1 IMPORTER/EXPORTER CORPORATION</CompanyName>
              <Country>
                <Code>AU</Code>
                <Name>Australia</Name>
              </Country>
              <Email>main.ausyd@au1importerexporter.com</Email>
              <Fax>+61285231223</Fax>
              <GovRegNum>23132835888</GovRegNum>
              <GovRegNumType>
                <Code>ABN</Code>
                <Description>Australian Business Number (GST Reg</Description>
              </GovRegNumType>
              <OrganizationCode>AU1IMPSYD</OrganizationCode>
              <Phone>+61285231212</Phone>
              <Port>
                <Code>AUSYD</Code>
                <Name>Sydney</Name>
              </Port>
              <Postcode>2747</Postcode>
              <State>NSW</State>
            </OrganizationAddress>
          </OrganizationAddressCollection>

          <PackingLineCollection Content="Complete">
            <PackingLine>
              <Commodity>
                <Code>GEN</Code>
                <Description>GENERAL</Description>
              </Commodity>
              <GoodsDescription>GOODS DESCRIPTION</GoodsDescription>
              <Link>1</Link>
              <PackQty>2</PackQty>
              <PackType>
                <Code>PKG</Code>
                <Description>Package</Description>
              </PackType>
              <Volume>1.78</Volume>
              <VolumeUnit>
                <Code>M3</Code>
                <Description>Cubic Metres</Description>
              </VolumeUnit>
              <Weight>156</Weight>
              <WeightUnit>
                <Code>KG</Code>
                <Description>Kilograms</Description>
              </WeightUnit>
            </PackingLine>
          </PackingLineCollection>

          <TransportLegCollection>
            <TransportLeg>
              <PortOfDischarge>
                <Code>AUSYD</Code>
                <Name>Sydney</Name>
              </PortOfDischarge>
              <PortOfLoading>
                <Code>USLAX</Code>
                <Name>Los Angeles</Name>
              </PortOfLoading>
              <LegOrder>0</LegOrder>
              <EstimatedArrival>2017-09-22T06:20:00</EstimatedArrival>
              <EstimatedDeparture>2017-09-20T22:30:00</EstimatedDeparture>
              <LegType>Flight1</LegType>
              <TransportMode>Air</TransportMode>
              <VoyageFlightNo>QF12</VoyageFlightNo>
            </TransportLeg>
          </TransportLegCollection>
        </Shipment>
      </UniversalShipment>
    XML
    eadaptor_request(data)
  end

  def self.example_consol_shipment
    data = <<~XML
      <UniversalShipment xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
        <Shipment>
          <DataContext>
            <DataTargetCollection>
              <DataTarget>
                <Type>ForwardingConsol</Type>
              </DataTarget>
            </DataTargetCollection>
          </DataContext>
          <AgentsReference>C000093945</AgentsReference>
          <AWBServiceLevel>
            <Code>STD</Code>
            <Description>Standard</Description>
          </AWBServiceLevel>
          <BookingConfirmationReference>908566322</BookingConfirmationReference>
          <ContainerCount>1</ContainerCount>
          <ContainerMode>
            <Code>FCL</Code>
            <Description>Full Container Load</Description>
          </ContainerMode>
          <DocumentedChargeable>17.89</DocumentedChargeable>
          <DocumentedVolume>17.89</DocumentedVolume>
          <DocumentedWeight>13568</DocumentedWeight>
          <LloydsIMO>9298636</LloydsIMO>
          <ManifestedChargeable>17.89</ManifestedChargeable>
          <ManifestedVolume>17.89</ManifestedVolume>
          <ManifestedWeight>13568</ManifestedWeight>
          <NoCopyBills>3</NoCopyBills>
          <NoOriginalBills>3</NoOriginalBills>
          <OuterPacks>0</OuterPacks>
          <PaymentMethod>
            <Code>PPD</Code>
            <Description>Prepaid</Description>
          </PaymentMethod>
          <PlaceOfDelivery>
            <Code>BRRIO</Code>
            <Name>Rio de Janeiro</Name>
          </PlaceOfDelivery>
          <PlaceOfIssue>
            <Code>USNYC</Code>
            <Name>New York</Name>
          </PlaceOfIssue>
          <PlaceOfReceipt>
            <Code>USNYC</Code>
            <Name>New York</Name>
          </PlaceOfReceipt>
          <PortOfDischarge>
            <Code>BRRIO</Code>
            <Name>Rio de Janeiro</Name>
          </PortOfDischarge>
          <PortOfLoading>
            <Code>USNYC</Code>
            <Name>New York</Name>
          </PortOfLoading>
          <ReleaseType>
            <Code>OBR</Code>
            <Description>Original Bill Required at Destination</Description>
          </ReleaseType>
          <ScreeningStatus>
            <Code>UNK</Code>
            <Description>Unknown</Description>
          </ScreeningStatus>
          <ShipmentType>
            <Code>DRT</Code>
            <Description>Direct</Description>
          </ShipmentType>
          <TotalNoOfPacks>20</TotalNoOfPacks>
          <TotalNoOfPacksPackageType>
            <Code>PKG</Code>
            <Description>Package</Description>
          </TotalNoOfPacksPackageType>
          <TotalVolume>17.89</TotalVolume>
          <TotalVolumeUnit>
            <Code>M3</Code>
            <Description>Cubic Metres</Description>
          </TotalVolumeUnit>
          <TotalWeight>13568</TotalWeight>
          <TotalWeightUnit>
            <Code>KG</Code>
            <Description>Kilograms</Description>
          </TotalWeightUnit>
          <TransportMode>
            <Code>SEA</Code>
            <Description>Sea Freight</Description>
          </TransportMode>
          <VesselName>DEMETER</VesselName>
          <VoyageFlightNo>25678N</VoyageFlightNo>
          <WayBillNumber>EISU908566322</WayBillNumber>
          <WayBillType>
            <Code>MWB</Code>
            <Description>Master Waybill</Description>
          </WayBillType>

          <AdditionalReferenceCollection Content="Complete">
            <AdditionalReference>
              <Type>
                <Code>CON</Code>
                <Description>Carrier Contract Number</Description>
              </Type>
              <ReferenceNumber>000985632</ReferenceNumber>
            </AdditionalReference>
            <AdditionalReference>
              <Type>
                <Code>LCR</Code>
                <Description>Letter Of Credit Number</Description>
              </Type>
              <ReferenceNumber>LC00003939/17</ReferenceNumber>
            </AdditionalReference>
          </AdditionalReferenceCollection>

          <ContainerCollection Content="Complete">
            <Container>
              <AirVentFlow>23.0</AirVentFlow>
              <AirVentFlowRateUnit>
                <Code>MQH</Code>
                <Description>Cubic metres per hour</Description>
              </AirVentFlowRateUnit>
              <ContainerNumber>ESLU0393941</ContainerNumber>
              <ContainerType>
                <Code>20RE</Code>
                <Category>
                  <Code>RFG</Code>
                  <Description>Refrigerated</Description>
                </Category>
                <Description>Twenty foot Reefer</Description>
                <ISOCode>22R0</ISOCode>
              </ContainerType>
              <DeliveryMode>CFS/CFS</DeliveryMode>
              <FCL_LCL_AIR>
                <Code>FCL</Code>
                <Description>Full Container Load</Description>
              </FCL_LCL_AIR>
              <GoodsWeight>13568</GoodsWeight>
              <GrossWeight>16068.000</GrossWeight>
              <GrossWeightVerificationDateTime>2017-10-19T18:52:00</GrossWeightVerificationDateTime>
              <GrossWeightVerificationType>
                <Code>PKG</Code>
                <Description>Method 2 - Packages</Description>
              </GrossWeightVerificationType>
              <HumidityPercent>26</HumidityPercent>
              <LengthUnit>
                <Code>FT</Code>
                <Description>Feet</Description>
              </LengthUnit>
              <Link>1</Link>
              <Seal>S0001</Seal>
              <SealPartyType>
                <Code>CAR</Code>
                <Description>Carrier/Shipping Line</Description>
              </SealPartyType>
              <TotalHeight>8.500</TotalHeight>
              <TotalLength>20.000</TotalLength>
              <TotalWidth>8.000</TotalWidth>
              <VolumeUnit>
                <Code>M3</Code>
                <Description>Cubic Metres</Description>
              </VolumeUnit>
              <WeightUnit>
                <Code>KG</Code>
                <Description>Kilograms</Description>
              </WeightUnit>
            </Container>
          </ContainerCollection>

          <DateCollection>
            <Date>
              <Type>BillIssued</Type>
              <IsEstimate>false</IsEstimate>
              <Value>2017-10-27T00:00:00</Value>
            </Date>
          </DateCollection>

          <NoteCollection Content="Partial">
            <Note>
              <Description>Goods Handling Instructions</Description>
              <IsCustomDescription>false</IsCustomDescription>
              <NoteText>REEFER CARGO PLEASE KEEP TEMPERATURE BETWEEN -2C AND 5C.</NoteText>
              <NoteContext>
                <Code>AAA</Code>
                <Description>Module: A - All, Direction: A - All, Freight: A - All</Description>
              </NoteContext>
              <Visibility>
                <Code>PUB</Code>
                <Description>CLIENT-VISIBLE</Description>
              </Visibility>
            </Note>
          </NoteCollection>

          <OrganizationAddressCollection>
            <OrganizationAddress>
              <AddressType>ReceivingForwarderAddress</AddressType>
              <Address1>VIA CASA 123</Address1>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>VIA CASA 123</AddressShortCode>
              <City>RIO DE JANEIRO</City>
              <CompanyName>FORWARDING AGENT</CompanyName>
              <Country>
                <Code>BR</Code>
                <Name>Brazil</Name>
              </Country>
              <OrganizationCode>FORAGERIO</OrganizationCode>
              <Port>
                <Code>BRRIO</Code>
                <Name>Rio de Janeiro</Name>
              </Port>
              <Postcode>744</Postcode>
              <State>RJ</State>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>ShippingLineAddress</AddressType>
              <Address1>Level 13 181 Miller Street</Address1>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>OFC: Level 13</AddressShortCode>
              <City>NORTH SYDNEY</City>
              <CompanyName>EVERGREEN MARINE (EISU)</CompanyName>
              <Country>
                <Code>AU</Code>
                <Name>Australia</Name>
              </Country>
              <OrganizationCode>EVEMAR_WW</OrganizationCode>
              <Port>
                <Code>AUSYD</Code>
                <Name>Sydney</Name>
              </Port>
              <Postcode>2060</Postcode>
              <State>NSW</State>

              <RegistrationNumberCollection>
                <RegistrationNumber>
                  <Type>
                    <Code>CCC</Code>
                    <Description>Standard Carrier Alpha Code</Description>
                  </Type>
                  <CountryOfIssue>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </CountryOfIssue>
                  <Value>EISU</Value>
                </RegistrationNumber>
              </RegistrationNumberCollection>
            </OrganizationAddress>
            <OrganizationAddress>
              <AddressType>SendingForwarderAddress</AddressType>
              <Address1>SUITE 18967, WISETECH GLOBAL USA BUILDING</Address1>
              <Address2>1515 SOUTH EASTERN WOODFIELD ROAD</Address2>
              <AddressOverride>false</AddressOverride>
              <AddressShortCode>1515 EAST WOODFIELD ROAD</AddressShortCode>
              <City>NEW YORK</City>
              <CompanyName>U.S. Demo Company</CompanyName>
              <Country>
                <Code>US</Code>
                <Name>United States</Name>
              </Country>
              <Email>address@wisglojfk.com</Email>
              <Fax>+18473649707</Fax>
              <OrganizationCode>WISGLOJFK</OrganizationCode>
              <Phone>+18473645600</Phone>
              <Port>
                <Code>USJFK</Code>
                <Name>John F. Kennedy Apt/New York</Name>
              </Port>
              <Postcode>00444</Postcode>
              <State>NY</State>
            </OrganizationAddress>
          </OrganizationAddressCollection>

          <SubShipmentCollection>
            <SubShipment>
              <DataContext>
                <DataTargetCollection>
                  <DataTarget>
                    <Type>ForwardingShipment</Type>
                  </DataTarget>
                </DataTargetCollection>
              </DataContext>

              <ActualChargeable>17.890</ActualChargeable>
              <BookingConfirmationReference>S000393845</BookingConfirmationReference>
              <ContainerCount>1</ContainerCount>
              <ContainerMode>
                <Code>FCL</Code>
                <Description>Full Container Load</Description>
              </ContainerMode>
              <DocumentedChargeable>17.890</DocumentedChargeable>
              <DocumentedVolume>17.890</DocumentedVolume>
              <DocumentedWeight>13568.000</DocumentedWeight>
              <HBLAWBChargesDisplay>
                <Code>SHW</Code>
                <Description>Show Collect Charges</Description>
              </HBLAWBChargesDisplay>
              <LloydsIMO>9298636</LloydsIMO>
              <ManifestedChargeable>17.890</ManifestedChargeable>
              <ManifestedVolume>17.890</ManifestedVolume>
              <ManifestedWeight>13568.000</ManifestedWeight>
              <NoCopyBills>1</NoCopyBills>
              <NoOriginalBills>0</NoOriginalBills>
              <OuterPacks>20</OuterPacks>
              <OuterPacksPackageType>
                <Code>PLT</Code>
                <Description>Pallet</Description>
              </OuterPacksPackageType>
              <PackingOrder>0</PackingOrder>
              <PortOfDestination>
                <Code>BRRIO</Code>
                <Name>Rio de Janeiro</Name>
              </PortOfDestination>
              <PortOfDischarge>
                <Code>BRRIO</Code>
                <Name>Rio de Janeiro</Name>
              </PortOfDischarge>
              <PortOfLoading>
                <Code>USNYC</Code>
                <Name>New York</Name>
              </PortOfLoading>
              <PortOfOrigin>
                <Code>USNYC</Code>
                <Name>New York</Name>
              </PortOfOrigin>
              <ReleaseType>
                <Code>EBL</Code>
                <Description>Express Bill of Lading</Description>
              </ReleaseType>
              <ServiceLevel>
                <Code>STD</Code>
                <Description>Standard Service</Description>
              </ServiceLevel>
              <ShipmentIncoTerm>
                <Code>FOB</Code>
                <Description>Free On Board</Description>
              </ShipmentIncoTerm>
              <ShipmentType>
                <Code>STD</Code>
                <Description>Standard House</Description>
              </ShipmentType>
              <ShippedOnBoard>
                <Code>SHP</Code>
                <Description>Shipped</Description>
              </ShippedOnBoard>
              <TotalVolume>17.890</TotalVolume>
              <TotalVolumeUnit>
                <Code>M3</Code>
                <Description>Cubic Metres</Description>
              </TotalVolumeUnit>
              <TotalWeight>13568.000</TotalWeight>
              <TotalWeightUnit>
                <Code>KG</Code>
                <Description>Kilograms</Description>
              </TotalWeightUnit>
              <TransportMode>
                <Code>SEA</Code>
                <Description>Sea Freight</Description>
              </TransportMode>
              <VesselName>DEMETER</VesselName>
              <VoyageFlightNo>25678N</VoyageFlightNo>
              <WayBillNumber>H00929300</WayBillNumber>
              <WayBillType>
                <Code>HWB</Code>
                <Description>House Waybill</Description>
              </WayBillType>

              <DateCollection>
                <Date>
                  <Type>Departure</Type>
                  <IsEstimate>true</IsEstimate>
                  <Value>2017-10-28T00:00:00</Value>
                </Date>
                <Date>
                  <Type>Arrival</Type>
                  <IsEstimate>true</IsEstimate>
                  <Value>2017-12-02T00:00:00</Value>
                </Date>
              </DateCollection>

              <EntryNumberCollection>
                <EntryNumber>
                  <Number>X10020005962</Number>
                  <Type>
                    <Code>ITN</Code>
                    <Description>Internal Transaction Number</Description>
                  </Type>
                  <CountryOfIssue>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </CountryOfIssue>
                  <EntryIsSystemGenerated>false</EntryIsSystemGenerated>
                </EntryNumber>
              </EntryNumberCollection>


              <OrganizationAddressCollection>
                <OrganizationAddress>
                  <AddressType>ConsignorDocumentaryAddress</AddressType>
                  <Address1>300 PARK AVE S</Address1>
                  <AddressOverride>false</AddressOverride>
                  <AddressShortCode>300 PARK AVENUE SOUTH</AddressShortCode>
                  <City>NEW YORK</City>
                  <CompanyName>ABC INTERNATIONAL PUBLICATIONS</CompanyName>
                  <Contact>Rino Balabat</Contact>
                  <Country>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </Country>
                  <Email>rbalatbat@randomhouse.com</Email>
                  <Fax>+12123872525</Fax>
                  <OrganizationCode>RIZINTNYC</OrganizationCode>
                  <Phone>+12123873400</Phone>
                  <Port>
                    <Code>USNYC</Code>
                    <Name>New York</Name>
                  </Port>
                  <Postcode>10010</Postcode>
                  <State>NY</State>
                </OrganizationAddress>
                <OrganizationAddress>
                  <AddressType>ConsignorPickupDeliveryAddress</AddressType>
                  <Address1>300 PARK AVE S</Address1>
                  <AddressOverride>false</AddressOverride>
                  <AddressShortCode>300 PARK AVENUE SOUTH</AddressShortCode>
                  <City>NEW YORK</City>
                  <CompanyName>ABC INTERNATIONAL PUBLICATIONS</CompanyName>
                  <Country>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </Country>
                  <Email>agreenwood@sterlingpub.com</Email>
                  <Fax>+12123872525</Fax>
                  <OrganizationCode>RIZINTNYC</OrganizationCode>
                  <Phone>+12123873400</Phone>
                  <Port>
                    <Code>USNYC</Code>
                    <Name>New York</Name>
                  </Port>
                  <Postcode>10010</Postcode>
                  <State>NY</State>
                </OrganizationAddress>
                <OrganizationAddress>
                  <AddressType>ConsigneeDocumentaryAddress</AddressType>
                  <Address1>ESTRADA DO SOPOTO 139</Address1>
                  <Address2>RJ, DO CENTRO</Address2>
                  <AddressOverride>false</AddressOverride>
                  <AddressShortCode>OFC: DOM IDILIO JOSE SOAR</AddressShortCode>
                  <City>IGUABA GRANDE</City>
                  <CompanyName>XYSS REPRESENTACOES LTDA PCA</CompanyName>
                  <Contact>Mr Contact</Contact>
                  <Country>
                    <Code>BR</Code>
                    <Name>Brazil</Name>
                  </Country>
                  <Email>Contact@mercoshi.com</Email>
                  <OrganizationCode>MERAGERIO</OrganizationCode>
                  <Phone>+55 (13) 322-1186</Phone>
                  <Port>
                    <Code>BRRIO</Code>
                    <Name>Rio de Janeiro</Name>
                  </Port>
                  <Postcode>28960000</Postcode>
                  <State>RJ</State>
                </OrganizationAddress>
                <OrganizationAddress>
                  <AddressType>ConsigneePickupDeliveryAddress</AddressType>
                  <Address1>ESTRADA DO SOPOTO 139</Address1>
                  <Address2>RJ, DO CENTRO</Address2>
                  <AddressOverride>false</AddressOverride>
                  <AddressShortCode>OFC: DOM IDILIO JOSE SOAR</AddressShortCode>
                  <City>IGUABA GRANDE</City>
                  <CompanyName>XYZS REPRESENTACOES LTDA PCA</CompanyName>
                  <Country>
                    <Code>BR</Code>
                    <Name>Brazil</Name>
                  </Country>
                  <GovRegNum>3930494889</GovRegNum>
                  <GovRegNumType>
                    <Code>CJN</Code>
                    <Description>CNPJ Cadastro Nacional da Pessoa Ju</Description>
                  </GovRegNumType>
                  <OrganizationCode>MERAGERIO</OrganizationCode>
                  <Phone>+55 (13) 322-1186</Phone>
                  <Port>
                    <Code>BRRIO</Code>
                    <Name>Rio de Janeiro</Name>
                  </Port>
                  <Postcode>28960000</Postcode>
                  <State>RJ</State>
                </OrganizationAddress>
                <OrganizationAddress>
                  <AddressType>SendersLocalClient</AddressType>
                  <Address1>300 PARK AVE S</Address1>
                  <AddressOverride>false</AddressOverride>
                  <AddressShortCode>300 PARK AVENUE SOUTH</AddressShortCode>
                  <City>NEW YORK</City>
                  <CompanyName>ABC INTERNATIONAL PUBLICATIONS</CompanyName>
                  <Country>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </Country>
                  <Email>agreenwood@sterlingpub.com</Email>
                  <Fax>+12123872525</Fax>
                  <OrganizationCode>RIZINTNYC</OrganizationCode>
                  <Phone>+12123873400</Phone>
                  <Port>
                    <Code>USNYC</Code>
                    <Name>New York</Name>
                  </Port>
                  <Postcode>10010</Postcode>
                  <State>NY</State>
                </OrganizationAddress>
              </OrganizationAddressCollection>

              <PackingLineCollection Content="Complete">
                <PackingLine>
                  <Commodity>
                    <Code>HAZ</Code>
                    <Description>Hazardous</Description>
                  </Commodity>
                  <ContainerLink>1</ContainerLink>
                  <ContainerNumber>ESLU0393941</ContainerNumber>
                  <ContainerPackingOrder>1</ContainerPackingOrder>
                  <CountryOfOrigin>
                    <Code>US</Code>
                    <Name>United States</Name>
                  </CountryOfOrigin>
                  <DetailedDescription>31752PCS OF ADAPTER 3000PCS OF POWER SUPPLY (912 CTNS PACKED IN 22 PLASTIC PLTS) (W/O BATTERY)

      (INV NO.172356) HS:8504409999

      THIS SHIPMENT CONTAINS NO WOOD PACKING MATERIAL</DetailedDescription>
                  <EndItemNo>0</EndItemNo>
                  <HarmonisedCode>8504409999</HarmonisedCode>
                  <Height>0.500</Height>
                  <ItemNo>0</ItemNo>
                  <Length>0.500</Length>
                  <LengthUnit>
                    <Code>M</Code>
                    <Description>Metres</Description>
                  </LengthUnit>
                  <LinePrice>0.0000</LinePrice>
                  <Link>1</Link>
                  <MarksAndNos>MEDELA INC. P/O : 401296 C/NO. 1-882 C/NO. 1-30 MADE IN CHINA</MarksAndNos>
                  <PackQty>20</PackQty>
                  <PackType>
                    <Code>PLT</Code>
                    <Description>Pallet</Description>
                  </PackType>
                  <Volume>17.890</Volume>
                  <VolumeUnit>
                    <Code>M3</Code>
                    <Description>Cubic Metres</Description>
                  </VolumeUnit>
                  <Weight>13568.000</Weight>
                  <WeightUnit>
                    <Code>KG</Code>
                    <Description>Kilograms</Description>
                  </WeightUnit>
                  <Width>0.500</Width>

                  <PackedItemCollection>
                  </PackedItemCollection>

                  <UNDGCollection>
                    <UNDG>
                      <Contact>
                        <FullName>BARB MAHONEY</FullName>
                        <Phone>+16306162393</Phone>
                      </Contact>
                      <FlashPoint>-3.0</FlashPoint>
                      <IMOClass>4.1</IMOClass>
                      <MarinePollutant>
                        <Code>Y</Code>
                        <Description>Marine Pollutant</Description>
                      </MarinePollutant>
                      <PackedInLimitedQuantity>false</PackedInLimitedQuantity>
                      <PackingGroup>I</PackingGroup>
                      <ProperShippingName>SODIUM DINITRO-o-CRESOLATE, WETTED</ProperShippingName>
                      <SubLabel1>6.1</SubLabel1>
                      <TechicalName>TECHNICAL NAME</TechicalName>
                      <UNDGCode>3369</UNDGCode>
                    </UNDG>
                  </UNDGCollection>
                </PackingLine>
              </PackingLineCollection>
            </SubShipment>
          </SubShipmentCollection>

          <TransportLegCollection>
            <TransportLeg>
              <PortOfDischarge>
                <Code>ESALG</Code>
                <Name>Algeciras</Name>
              </PortOfDischarge>
              <PortOfLoading>
                <Code>USSPQ</Code>
                <Name>San Pedro</Name>
              </PortOfLoading>
              <LegOrder>2</LegOrder>
              <Carrier>
                <AddressType>Carrier</AddressType>
                <Address1>Level 13 181 Miller Street</Address1>
                <AddressOverride>false</AddressOverride>
                <AddressShortCode>OFC: Level 13</AddressShortCode>
                <City>NORTH SYDNEY</City>
                <CompanyName>EVERGREEN MARINE (EISU)</CompanyName>
                <Country>
                  <Code>AU</Code>
                  <Name>Australia</Name>
                </Country>
                <OrganizationCode>EVEMAR_WW</OrganizationCode>
                <Port>
                  <Code>AUSYD</Code>
                  <Name>Sydney</Name>
                </Port>
                <Postcode>2060</Postcode>
                <State>NSW</State>

                <RegistrationNumberCollection>
                  <RegistrationNumber>
                    <Type>
                      <Code>CCC</Code>
                      <Description>Standard Carrier Alpha Code</Description>
                    </Type>
                    <CountryOfIssue>
                      <Code>US</Code>
                      <Name>United States</Name>
                    </CountryOfIssue>
                    <Value>EISU</Value>
                  </RegistrationNumber>
                </RegistrationNumberCollection>
              </Carrier>
              <EstimatedArrival>2017-11-11T00:00:00</EstimatedArrival>
              <EstimatedDeparture>2017-11-01T00:00:00</EstimatedDeparture>
              <IsCargoOnly>false</IsCargoOnly>
              <LegType>Main</LegType>
              <TransportMode>Sea</TransportMode>
              <VesselLloydsIMO>9298636</VesselLloydsIMO>
              <VesselName>DEMETER</VesselName>
              <VoyageFlightNo>25678N</VoyageFlightNo>
            </TransportLeg>
            <TransportLeg>
              <PortOfDischarge>
                <Code>BRRIO</Code>
                <Name>Rio de Janeiro</Name>
              </PortOfDischarge>
              <PortOfLoading>
                <Code>BRSSZ</Code>
                <Name>Santos</Name>
              </PortOfLoading>
              <LegOrder>3</LegOrder>
              <Carrier>
                <AddressType>Carrier</AddressType>
                <Address1>Level 13 181 Miller Street</Address1>
                <AddressOverride>false</AddressOverride>
                <AddressShortCode>OFC: Level 13</AddressShortCode>
                <City>NORTH SYDNEY</City>
                <CompanyName>EVERGREEN MARINE (EISU)</CompanyName>
                <Country>
                  <Code>AU</Code>
                  <Name>Australia</Name>
                </Country>
                <OrganizationCode>EVEMAR_WW</OrganizationCode>
                <Port>
                  <Code>AUSYD</Code>
                  <Name>Sydney</Name>
                </Port>
                <Postcode>2060</Postcode>
                <State>NSW</State>

                <RegistrationNumberCollection>
                  <RegistrationNumber>
                    <Type>
                      <Code>CCC</Code>
                      <Description>Standard Carrier Alpha Code</Description>
                    </Type>
                    <CountryOfIssue>
                      <Code>US</Code>
                      <Name>United States</Name>
                    </CountryOfIssue>
                    <Value>EISU</Value>
                  </RegistrationNumber>
                </RegistrationNumberCollection>
              </Carrier>
              <EstimatedArrival>2017-12-02T00:00:00</EstimatedArrival>
              <EstimatedDeparture>2017-11-26T00:00:00</EstimatedDeparture>
              <LegType>Other</LegType>
              <TransportMode>Sea</TransportMode>
              <VesselLloydsIMO>9333058</VesselLloydsIMO>
              <VesselName>STADT KOLN</VesselName>
              <VoyageFlightNo>272GBN</VoyageFlightNo>
            </TransportLeg>
            <TransportLeg>
              <PortOfDischarge>
                <Code>USSPQ</Code>
                <Name>San Pedro</Name>
              </PortOfDischarge>
              <PortOfLoading>
                <Code>USNYC</Code>
                <Name>New York</Name>
              </PortOfLoading>
              <LegOrder>1</LegOrder>
              <EstimatedArrival>2017-10-30T00:00:00</EstimatedArrival>
              <EstimatedDeparture>2017-10-28T00:00:00</EstimatedDeparture>
              <LegType>Other</LegType>
              <TransportMode>Rail</TransportMode>
            </TransportLeg>
          </TransportLegCollection>
        </Shipment>
      </UniversalShipment>
    XML
    eadaptor_request(data)
  end
end
