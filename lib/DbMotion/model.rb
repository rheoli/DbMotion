module DbMotion
  class Model
    
    def self.get_version(_version)
      @@models["#{sprintf "%03d", _version}"]
    end
    
    def self.versions
      @@models.keys.sort.map do |v|
        @@models[v]
      end
    end
    
    def self.version(_version, &block)
      return if _version==0
      @@models||={}
      e = Entities.new(&block)
      model = e.mom_model
      if model.nil?
        model = NSManagedObjectModel.alloc.init
        model.entities=e.entities.values
      end
      @@models["#{sprintf "%03d", _version}"]=model
    end
    
  end
  
  class Entities
    attr_reader :entities, :mom_model

    def initialize(&block)
      @entities  = {}
      @mom_model = nil
      block.call(self)
    end
    
    def mom_file(_mom_file)
      @mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{_mom_file}")
      @mom_model=NSManagedObjectModel.alloc.initWithContentsOfURL(@mom_url)
    end
    
    def entity(_name, &block)
      e = Entity.new(&block)
      entity = NSEntityDescription.alloc.init
      entity.name = _name
      entity.managedObjectClassName = _name
      entity.properties = e.attributes.map do |type, name|
        property = NSAttributeDescription.alloc.init
        property.name = name
        property.attributeType = type
        property.optional = true
        property
      end
      @entities[_name]=entity
    end
    
    def relation(_relation)
      # Example "model1 <->> model2"
      relation=_relation.split(/ /)
      if relation.size!=3
        puts "Unknown relation"
        return
      end
      if (relation[1]=~/^<{1,2}\->{1,2}$/).nil?
        puts "Unknown relation type"
        return
      end
      model1_info=relation[0].split(/:/)
      model2_info=relation[2].split(/:/)
      unless @entities.has_key?(model1_info[0]) and @entities.has_key?(model2_info[0])
        puts "Relation partner not found #{relation}"
        return
      end
      
      model1 = NSRelationshipDescription.alloc.init
      model2 = NSRelationshipDescription.alloc.init
      
      model1.name                = model1_info[1]
      model1.destinationEntity   = @entities[model2_info[0]]
      model1.inverseRelationship = model2
      model1.deleteRule          = NSNullifyDeleteRule
      if relation[1]=~/>>$/
        # ->>
        model1.minCount            = 0
        model1.maxCount            = -1
      else
        # ->
        model1.minCount            = 1
        model1.maxCount            = 1
        model1.optional            = true
      end
      
      model2.name                = model2_info[1]
      model2.destinationEntity   = @entities[model1_info[0]]
      model2.inverseRelationship = model1
      model2.deleteRule          = NSNullifyDeleteRule
      if relation[1]=~/^<</
        # <<-
        model2.minCount            = 0
        model2.maxCount            = -1
      else
        # <-
        model2.minCount            = 1
        model2.maxCount            = 1
        model2.optional            = true
      end
      
      @entities[model1_info[0]].properties=@entities[model1_info[0]].properties+[model1]
      @entities[model2_info[0]].properties=@entities[model2_info[0]].properties+[model2]
    end
    
  end
  
  class Entity
    attr_reader :attributes

    MAPPING={
      string:  NSStringAttributeType,
      integer: NSInteger16AttributeType,
      double:  NSDoubleAttributeType,
      float: NSFloatAttributeType,
      decimal: NSDecimalAttributeType,
      boolean: NSBooleanAttributeType,
      date:    NSDateAttributeType,
      bindata: NSBinaryDataAttributeType,    
    }

    def initialize(&block)
      @attributes = []
      block.call(self)
    end
    
    def method_missing(meth, *args, &block)
      if MAPPING.has_key?(meth.to_sym)
        @attributes << [MAPPING[meth.to_sym], args[0]]
      else
        puts "Key #{meth} not found"
      end
    end
  end
end
