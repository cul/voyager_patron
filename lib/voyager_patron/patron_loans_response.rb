require 'nokogiri'

module VoyagerLoansResponse
  
  class Loans
    
    attr_accessor :items
    
    def initialize(response, vxws_url)
      begin
        response = Nokogiri::XML(response)
        self.items = {}
        response.xpath("//loan").each do |loan|
          self.items[loan.xpath("itemId").text] = {:href => clean_uri(loan.attr('href'), vxws_url), :canrenew => clean_can_renew(loan.attr('canRenew'))}
        end
      rescue
        # Do Something
      end
    end
    
    private
      
    def clean_uri(href, vxws_url)
      # From: "http://127.0.0.1:7614/vxws/patron/117768/circulationActions/loans/1@STOUTDB20010209055455|589926?patron_homedb=1@LACROSSDB20010201061906"
      # To:   "http://lacvoyapp.wisconsin.edu:7614/vxws/patron/117768/circulationActions/loans/1@STOUTDB20010209055455|589926?patron_homedb=1@LACROSSDB20010201061906"
      href = vxws_url + href.split("/vxws/")[1]
    end
    
    def clean_can_renew(canrenew)
      canrenew = canrenew == "Y" ? true : false
    end
  end
  
  class Renewals
    
    attr_accessor :response
    
    def initialize(response)
      begin
        response = Nokogiri::XML(response)
        self.response = {}
        response.xpath("//loan").each do |renewal|
          self.response[renewal.xpath("itemId").text] = {
            :renewal_status => renewal.xpath("renewalStatus").text
          }
        end
      rescue
        File.open("log/voyager_errors.log", "a") {|f| 
          f.puts "\n\n
          ===Error parsing renewal response===\n 
          RESPONSE = #{response.inspect}"
        }
        self.response = nil
      end
    end
  end
end