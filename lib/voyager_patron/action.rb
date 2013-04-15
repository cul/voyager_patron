module VoyagerPatron
  class Action
    attr_accessor :name, :url, :allowed, :note
    
    def initialize(action)
      self.name = action.type
      self.url = action.href
      self.allowed = action.allowed == "Y" if action.allowed
      self.note = action.note if action.note
    end
  end
end
