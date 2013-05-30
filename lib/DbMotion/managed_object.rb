module DbMotion

  class ManagedObject < NSManagedObject
  
    def to_url
      self.objectID.URIRepresentation.absoluteString
    end
  
  	def to_s
  		get_title
  	end
  
    def get_title
      self.name
    end
    #alias :title :get_title
    
    def get_subtitle
      nil
    end
    #alias :subtitle :get_subtitle
    
    def has_subtitle
      false
    end
  
    def get_coordinate
      return nil if !self.respond_to?("pos_lat") or !self.respond_to?("pos_lon")
      return nil if self.pos_lat.nil? or self.pos_lon.nil?
      return nil if (self.pos_lat*100.0).to_i==0 and (self.pos_lon*100.0).to_i==0
      ::CLLocationCoordinate2D.new(self.pos_lat, self.pos_lon)
    end
    #alias :coordinate :get_coordinate
  
  
    def now_created
      self.created=NSDate.date if self.respond_to?("created")
    end
  
    def now_changed
      self.changed=NSDate.date if self.respond_to?("changed")
    end
  
    def is_changed
      return false if !self.changed.is_a?(NSDate)
      #p NSDate.date.timeIntervalSinceDate(self.changed)
      return true if NSDate.date.timeIntervalSinceDate(self.changed)<100.0
      false
    end
  
    def is_created
      return false if !self.created.is_a?(NSDate)
      #p NSDate.date.timeIntervalSinceDate(self.created)
      return true if NSDate.date.timeIntervalSinceDate(self.created)<100.0
      false
    end
    
  end

end