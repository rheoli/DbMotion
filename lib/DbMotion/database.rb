module DbMotion
  class Database
  
    def self.shared
      @@db
    end
  
    def self.setSharedSession(_db)
      @@db=_db
    end
  
    def create_entry(_name)
      NSEntityDescription.insertNewObjectForEntityForName(_name, inManagedObjectContext:@context)
    end
  
    def get_obj_id_from_url(_url)
      @context.persistentStoreCoordinator.managedObjectIDForURIRepresentation(url)
    end
  
    def get_url_from_obj_id(_obj_id)
      _obj_id.URIRepresentation
    end
  
    def find_by_obj_id(_obj_id)
      error_ptr = Pointer.new(:object)
      @context.existingObjectWithID(_obj_id, error:error_ptr)
    end
  
    # Example: _sort=[NSSortDescriptor.alloc.initWithKey('name', ascending:true)] 
    def find_entry(_name, _sort=[])
      request = NSFetchRequest.alloc.init
      request.entity = NSEntityDescription.entityForName(_name, inManagedObjectContext:@context)
      request.sortDescriptors = _sort
      error_ptr = Pointer.new(:object)
      @context.executeFetchRequest(request, error:error_ptr)
    end

    def delete_entry(_obj)
      @context.deleteObject(_obj)
    end
  
    def save
      error_ptr = Pointer.new(:object)
      @context.save(error_ptr)
    end
  
    def open(_db_file, _model)
      @model=_model.versions.last
      @store = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model)
      @store_file = File.join(NSHomeDirectory(), 'Documents', _db_file)
      @store_url  = NSURL.fileURLWithPath(@store_file)
      unless compatible?
        migrate(_model.versions)
      end
      @context = NSManagedObjectContext.alloc.init
      @context.persistentStoreCoordinator = @store
      error_ptr = Pointer.new(:object)
      unless @store.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:@store_url, options:nil, error:error_ptr)
        raise "Can't add persistent SQLite store: #{error_ptr[0].description}"
      end
      self
    end
  
    def compatible?
      error_ptr = Pointer.new(:object)
      metadata=NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL:@store_url, error:error_ptr)
      compatible=true
      if metadata
        compatible=@model.isConfiguration(nil, compatibleWithStoreMetadata:metadata)
      end
      compatible
    end
  
    def migrate_model(_old_model, _new_model)
      error_ptr = Pointer.new(:object)
      migmgr=NSMigrationManager.alloc.initWithSourceModel(_old_model, destinationModel:_new_model)
      mapping_model = NSMappingModel.inferredMappingModelForSourceModel(_old_model, destinationModel:_new_model, error:error_ptr)
      new_store_url = NSURL.fileURLWithPath(@store_url.path+".new")
      ret=migmgr.migrateStoreFromURL(@store_url, type:NSSQLiteStoreType, options:nil,
                                withMappingModel:mapping_model, toDestinationURL:new_store_url,
                                destinationType:NSSQLiteStoreType, destinationOptions:nil,
                                error:error_ptr)
      NSLog "Migration result #{ret}."
      if ret
        NSFileManager.defaultManager.removeItemAtPath(@store_url.path, error:error_ptr)
        NSFileManager.defaultManager.moveItemAtPath(new_store_url.path, toPath:@store_url.path, error:error_ptr)
      end
      ret
    end
  
    def migrate(_models)
      error_ptr = Pointer.new(:object)
      metadata=NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL:@store_url, error:error_ptr)
      return false unless metadata
      found=false
      old_model=nil
      _models.each do |model|
        unless found
          found=model.isConfiguration(nil, compatibleWithStoreMetadata:metadata)
          if found
            old_model=model
            NSLog "Found version #{model}"
          end
        else
          if migrate_model(old_model, model)
            old_model=model
          end
        end
      end
      unless found
        NSLog "Model not found....?!"
      end
    end
  
  end
end

