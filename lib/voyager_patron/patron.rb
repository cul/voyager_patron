require 'httpclient'

module VoyagerPatron
  class Patron 
    
    attr_accessor :server, :library, :voyager_identifier, :full_name, :last_name, 
        :barcode, :institution_id, :home_db, :account, :loans, :logger

    def initialize(server, args)
      @server = server
      
      if args[:last_name] and (args[:institution_id] or args[:barcode])
        self.last_name = args[:last_name] if args[:last_name] 
        self.barcode = args[:barcode] if args[:barcode] 
        self.institution_id = args[:institution_id] if args[:institution_id] 
        self.library = args[:library]
      else
        raise ArgumentError, "must pass :last_name and :barcode or :institution_id"
      end
      if authenticate
        load_account
        load_renewal_paths
      end
    end
    
    def authenticate
      begin
        url = @server.vxws_uri("AuthenticatePatronService")
        request = Net::HTTP::Post.new(url.path)
        request.body = self.post_data
        response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
        patron_info = Crack::XML.parse(response.body)
        self.voyager_identifier = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:patronIdentifier"]["patronId"]
        self.full_name = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:fullName"]
        self.barcode = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:barcode"]
        self.institution_id = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:institutionId"]
        self.last_name = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:lastName"]
        self.home_db = patron_info["ser:voyagerServiceData"]["ser:serviceData"]["pat:patronIdentifier"]["patronHomeUbId"]
        true
      rescue
        false
      end
    end

    def post_data
      
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<ser:serviceParameters xmlns:ser="http://www.endinfosys.com/Voyager/serviceParameters">'
      xml += '<ser:patronIdentifier lastName="' + self.last_name + '">'

        xml += '  <ser:authFactor type="I">' + self.institution_id + '</ser:authFactor>'        

      xml += '</ser:patronIdentifier>'
      xml += '</ser:serviceParameters>'
      
      xml
    end
    
    def load_account
      url  = @server.vxws_uri("MyAccountService?patronId=#{self.voyager_identifier}&patronHomeUbId=#{self.home_db}")

      response = Net::HTTP.get_response(url)
      begin
        self.account = VoyagerResponse::PatronAccount.parse(response.body, :single => true)
      rescue LibXML::XML::Error => e
        self.account = nil
      end
    end
    
    def load_renewal_paths
      url = @server.vxws_uri("patron/#{self.voyager_identifier}/circulationActions/loans?patron_homedb=#{self.home_db}&view=brief")
      response = Net::HTTP.get_response(url)
      begin
        vxws_url = @server.vxws_url()
        self.loans = VoyagerLoansResponse::Loans.new(response.body, vxws_url).items
      rescue LibXML::XML::Error => e
        RAILS_DEFAULT_LOGGER.debug("\n\n#{response.body}\n\n") if RAILS_DEFAULT_LOGGER
        self.loans = nil
      end
    end
    
    def restful_renewal(bib_id)
      # Using HTTPClient
      begin
        
        # Configure timeouts
        http = HTTPClient.new
        http.connect_timeout  = 10000
        http.receive_timeout  = 10000
        http.send_timeout     = 10000
        
        # Post Request
        response = http.post(URI.escape(self.loans[bib_id][:href])).content
      
      # Rescue from any Timeout Error
      rescue HTTPClient::ReceiveTimeoutError, HTTPClient::ConnectTimeoutError, HTTPClient::SendTimeoutError => timeout
        response = timeout
      
      # Rescue from all other Exceptions
      rescue Exception => ex
        File.open("log/voyager_errors.log", "a") {|f| 
          f.puts "\n\n
          ===Error renewing===\n 
          BibID: #{bib_id}\n
          URL: #{URI.escape(self.loans[bib_id][:href])}\n
          Exception:\n #{ex}"
        }
      end
    end
    
    def restful_bulk_renewal
      # Using HTTPClient
      begin
        
        url  = @server.vxws_url("patron/#{self.voyager_identifier}/circulationActions/loans?patron_homedb=#{self.home_db}&view=brief")
        
        # Configure timeouts
        http = HTTPClient.new
        http.connect_timeout  = 10000
        http.receive_timeout  = 10000
        http.send_timeout     = 10000
        
        # Post Request
        response = http.post(URI.escape(url)).content
      
      # Rescue from any Timeout Error
      rescue HTTPClient::ReceiveTimeoutError, HTTPClient::ConnectTimeoutError, HTTPClient::SendTimeoutError => timeout
        response = timeout
      
      # Rescue from all other Exceptions
      rescue Exception => ex
        File.open("log/voyager_errors.log", "a") {|f| 
          f.puts "\n\n
          ===Error renewing===\n 
          BibID: #{bib_id}\n
          URL: #{URI.escape(self.loans[bib_id][:href])}\n
          Exception:\n #{ex}"
        }
      end
    end

    def place_request_for(record, pickup_location_id, comment)
      request_placed = false
      expire_time = (Date.today >> 1).to_time
      expire_date = "#{expire_time.year}#{("%02d" % expire_time.month)}#{("%02d" % expire_time.day)}"
      comment = CGI::escapeHTML(comment)
      
      record.items.each do |item|
        unless request_placed
          xml = "<ub-request-parameters>" + 
                "<pickup-library>#{self.home_db}</pickup-library>" + 
                "<pickup-location>#{pickup_location_id}</pickup-location>" + 
                "<last-interest-date>#{expire_date}</last-interest-date>" + 
                "<dbkey>#{$libraries[record.library]["db_key"]}</dbkey>" + 
                "<comment>#{comment}</comment>" + 
                "</ub-request-parameters>"
          ub_url = "#{item.resource_url}/ubrequest?patron=#{self.voyager_identifier}&patron_homedb=#{self.home_db}"
          uri = URI.parse(ub_url)
          Net::HTTP.start(uri.host, uri.port) do |http|
            headers = {'Content-Type' => 'text/xml'}
            response = http.send_request('PUT', uri.request_uri, xml, headers)
            request_info = Crack::XML.parse(response.body)
            request_placed = true if request_info["response"]["reply_code"] == "0"
          end
        end
      end
      request_placed
    end
    
    def can_request?(record)
      can_request = false
      if record.patron.nil? or record.patron.voyager_identifier != self.voyager_identifier
        record = VoyagerApi::Record.new(:bib_id => record.bib_id, :library => record.library, :patron => self)
      end
      if record.items
        record.items.each do |item|
          item.actions.each do |action|
            can_request = true if action.name == "UBRequest" and action.allowed
          end
        end
      end
      can_request
    end
    
    # requested item must be a VoyagerResponse::RequestedItem
    def place_recall_for(record, pickup_location_id, comment)
      recalled = false
      expire_time = (Date.today >> 1).to_time
      expire_date = "#{expire_time.year}#{("%02d" % expire_time.month)}#{("%02d" % expire_time.day)}"
      comment = CGI::escapeHTML(comment)
      
      xml  = '<?xml version="1.0" encoding="UTF-8"?>'
      xml += '<recall-parameters>'
      xml += "<pickup-location>#{pickup_location_id}</pickup-location>"
      xml += "<last-interest-date>#{expire_date}</last-interest-date>"
      xml += "<dbkey>#{$libraries[record.library]["db_key"]}</dbkey>"
      xml += "<comment>#{comment}</comment>" 
      xml += '</recall-parameters>'
      
      recallable_item = record.items.reduce(nil) do |recallable_item, item|
        item.actions.reduce(recallable_item) do |recallable_item, action|
          unless recallable_item
            recallable_item = item if action.name == "Recall" and action.allowed
            recallable_item
          end
          recallable_item
        end
      end
      
      recall_url = "#{recallable_item.resource_url}/recall?patron=#{self.voyager_identifier}&patron_homedb=#{self.home_db}"
      uri = URI.parse(recall_url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = {'Content-Type' => 'text/xml'}
        response = http.send_request('PUT', uri.request_uri, xml, headers)
        request_info = Crack::XML.parse(response.body)
        recalled = true if request_info["response"]["reply_code"] == "0"
      end
      recalled
    end
    
    def can_recall?(record)
      if record.library != self.library
        false
      else
        if record.patron.nil? or record.patron.voyager_identifier != self.voyager_identifier
          record = VoyagerApi::Record.new(:bib_id => record.bib_id, :library => record.library, :patron => self)
        end
        record.items.reduce(false) do |can_recall, item|
          item.actions.reduce(can_recall) do |can_recall, action|
            can_recall = true if action.name == "Recall" and action.allowed
            can_recall
          end
        end
      end
    end
    
    # requested item must be a VoyagerResponse::RequestedItem
    def cancel_request_for(requested_item)
      url = @server.vxws_uri("CancelService")
      request = Net::HTTP::Post.new(url.path)
      request.body = cancel_request_post_data(requested_item)
      response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
      response.body
    end
    
    def cancel_request_post_data(requested_item)
      xml  = '<?xml version="1.0" encoding="UTF-8"?>'
      xml += '<ser:serviceParameters xmlns:ser="http://www.endinfosys.com/Voyager/serviceParameters">'
      xml += ' <ser:parameters/>'
      xml += '  <ser:patronIdentifier lastName="' + self.last_name + '" patronHomeUbId="' + self.home_db + '" patronId="' + self.voyager_identifier.to_s + '">'

      if ['WEU', 'WKenU', 'WLacU', 'WSpU'].include?(self.library)
        xml += '  <ser:authFactor type="I">' + self.barcode + '</ser:authFactor>'        
      else
        xml += '  <ser:authFactor type="B">' + self.barcode + '</ser:authFactor>'
      end
      
      xml += ' </ser:patronIdentifier>'
      xml += ' <ser:definedParameters xsi:type="myac:myAccountServiceParametersType" xmlns:myac="http://www.endinfosys.com/Voyager/myAccount" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      xml += '  <myac:requestIdentifier>'
      xml += '   <myac:itemID>' + requested_item.item_id.to_s + '</myac:itemID>'
      xml += '   <myac:holdRecallID>' + requested_item.hold_recall_id.to_s + '</myac:holdRecallID>'
      xml += '   <myac:holdType>' + requested_item.hold_type + '</myac:holdType>'
      xml += '   <myac:dbKey>' + requested_item.db_key + '</myac:dbKey>'
      xml += '  </myac:requestIdentifier>'
      xml += ' </ser:definedParameters>'
      xml += '</ser:serviceParameters>'
      xml
    end
    
    def renew_item(item_id, ub_id)
      url = URI.parse("http://#{$libraries[self.library]["host"]}:#{$libraries[self.library]["port"]}/vxws/RenewService")
      request = Net::HTTP::Post.new(url.path)
      request.body = renewal_post_data(item_id, ub_id)
      response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
      account_info = VoyagerResponse::PatronAccount.parse(response.body, :single => true)
      renewal_item = account_info.charged_item_list.library_clusters.reduce(nil) do |renewal_item, library_cluster|
        renewal_item = library_cluster.charged_items.reduce(renewal_item) do |renewal_item, item| 
          renewal_item = item if (item.item_id == item_id and library_cluster.library.ub_id == ub_id)
          renewal_item
        end
      end
      renewal_item
    end
    
    def renewal_post_data(item_id, ub_id)
      xml =  '<?xml version="1.0" encoding="UTF-8"?>'
      xml += '<ser:serviceParameters xmlns:ser="http://www.endinfosys.com/Voyager/serviceParameters">'
      xml += ' <ser:patronIdentifier lastName="' + self.last_name + '" patronHomeUbId="' + self.home_db + '" patronId="' + self.voyager_identifier.to_s + '">'

      if ['WEU', 'WKenU', 'WLacU', 'WSpU'].include?(self.library)
        xml += '  <ser:authFactor type="I">' + self.barcode + '</ser:authFactor>'        
      else
        xml += '  <ser:authFactor type="B">' + self.barcode + '</ser:authFactor>'
      end

      xml += ' </ser:patronIdentifier>'
      xml += ' <ser:definedParameters xsi:type="myac:myAccountServiceParametersType" xmlns:myac="http://www.endinfosys.com/Voyager/myAccount" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      xml += '  <myac:itemIdentifier>'
      xml += '   <myac:itemId>' + item_id + '</myac:itemId>'
      xml += '   <myac:ubId>' + ub_id + '</myac:ubId>'
      xml += '  </myac:itemIdentifier>'
      xml += ' </ser:definedParameters>'
      xml += '</ser:serviceParameters>'
      xml
    end
  end
end
