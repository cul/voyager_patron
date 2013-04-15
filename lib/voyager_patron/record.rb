module VoyagerPatron
  class Record
    attr_accessor :server, :library, :bib_id, :items, :patron

    def initialize(server, args)
      @server = server
      if args[:bib_id] and args[:library]
        self.bib_id = args[:bib_id]
        self.library = args[:library]
        self.patron = args[:patron] if args[:patron]
      else
        raise ArgumentError, "must pass :bib_id and :library"
      end
      get_items
    end
    
    def get_items
      url = @server.vxws_url("record/#{self.bib_id}/items")
      url += "?patron=#{patron.voyager_identifier}&patron_homedb=#{patron.home_db}" if patron
      url = URI.parse(url)
      begin
        request = Net::HTTP::Get.new(url.request_uri)
        response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
        record_info = VoyagerResponse::Record.parse(response.body, :single => true)
        self.items = []
        record_info.items.each {|item| self.items << Item.new(item)}
        self.items
      rescue
        
      end
    end
  
    def item_ids
      self.items.map { |item| item.item_id }
    end
  end
end
