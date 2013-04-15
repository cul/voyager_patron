module VoyagerResponse
  class Item
    attr_accessor :resource_url, :actions, :item_id, :credentials
    
    def initialize(server, item)
      @server = server

    	if item.is_a?(VoyagerResponse::Item)
				self.resource_url = item.href
      	self.item_id = resource_url[resource_url.rindex("/") + 1, resource_url.length - 1].to_i
				self.actions = []
				item.actions.each {|action| self.actions << Action.new(action)}
			elsif item.is_a?(Hash)
				if item[:bib_id] and item[:item_id] and item[:library]
				  self.item_id = item[:item_id]
					self.resource_url = get_resource_url(item[:bib_id], item[:item_id], item[:library])
				else
					raise ArgumentError, "initializing with a Hash must pass in :bib_id, :item_id and :library"
				end
			else
				raise ArgumentError, "must pass in a VoyagerResponse::Item or a Hash containing the :bib_id, :item_id and :library"
    	end
    end
    
    def get_resource_url(credentials, bib_id, item_id, library)
      @server.vxws_url("record/#{bib_id}/items/#{item_id}")
    end
  end
end
