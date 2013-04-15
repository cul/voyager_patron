module VoyagerPatron
  class Server

    attr_accessor :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def vxws_url(path = '')
      "http://#{@credentials['host']}:#{@credentials['port']}/vxws/#{path}"

    end
    
    def vxws_uri(path = '')
      URI.parse(vxws_url(path))
    end
  end
end
