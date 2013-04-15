module VoyagerResponse
  class Action
    include HappyMapper
    tag 'info'
    attribute :type, String
    attribute :href, String
    attribute :allowed, String
    element :note, String, :tag => 'note'
  end

  class Item
    include HappyMapper
    tag 'item'
    attribute :href, String
    has_many :actions, VoyagerResponse::Action
  end
  
  class Institution
    include HappyMapper
    tag 'institution'
    attribute :id, String
    element :name, String, :tag => 'instName'
    has_many :items, VoyagerResponse::Item
  end

  class ItemList
    include HappyMapper
    tag 'items'
    has_one :institution, Institution
  end

  class Record
    include HappyMapper
    tag 'response'
    element :reply_text, String, :tag => 'reply-text'
    element :reply_code, Integer, :tag => 'reply-code'
    has_one :item_list, ItemList
    
    def items
    	if self.item_list and self.item_list.institution
	      self.item_list.institution.items
	    else
	    	[]
	    end
    end
  end
end