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
  
    def open(_db_file, withModel: _model)
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
  
    def open(_db_file, withMOMFile: _mom_file)
      @mom_file=_mom_file % "cur"
      @mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{@mom_file}")
      @model=NSManagedObjectModel.alloc.initWithContentsOfURL(@mom_url)
      @store = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model)
      @store_file = File.join(NSHomeDirectory(), 'Documents', _db_file)
      @store_url  = NSURL.fileURLWithPath(@store_file)
      unless compatible?
        migrate_mom(_mom_file)
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
  
    def migrate_mom_model(_old_mom_url, _new_mom_url)
      error_ptr = Pointer.new(:object)
      new_model=NSManagedObjectModel.alloc.initWithContentsOfURL(_new_mom_url)
      old_model=NSManagedObjectModel.alloc.initWithContentsOfURL(_old_mom_url)
      migmgr=NSMigrationManager.alloc.initWithSourceModel(old_model, destinationModel:new_model)
      mapping_model = NSMappingModel.inferredMappingModelForSourceModel(old_model, destinationModel:new_model, error:error_ptr)
      new_store_url = NSURL.fileURLWithPath(@store_url.path+".new")
      ret=migmgr.migrateStoreFromURL(@store_url, type:NSSQLiteStoreType, options:nil,
                                withMappingModel:mapping_model, toDestinationURL:new_store_url,
                                destinationType:NSSQLiteStoreType, destinationOptions:nil,
                                error:error_ptr)
      NSLog "Migration result #{ret}."
      NSFileManager.defaultManager.removeItemAtPath(@store_url.path, error:error_ptr)
      NSFileManager.defaultManager.moveItemAtPath(new_store_url.path, toPath:@store_url.path, error:error_ptr)
    end
  
    def migrate_mom(_old_mom_files)
      old_mom_files=_old_mom_files % '%03d'
      error_ptr = Pointer.new(:object)
      metadata=NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL:@store_url, error:error_ptr)
      return false unless metadata
      db_version=-1
      0.upto(999) do |version|
        old_mom_file=old_mom_files % version
        NSLog [:migrate, "old mom file", old_mom_file].inspect
        old_mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{old_mom_file}")
        NSLog [:migrate, "old mom url", old_mom_url].inspect
        old_model=NSManagedObjectModel.alloc.initWithContentsOfURL(old_mom_url)
        compatible=old_model.isConfiguration(nil, compatibleWithStoreMetadata:metadata)
        next unless compatible
        db_version=version
        NSLog "Found version #{version}"
        break
      end
      db_version.upto(999) do |version|
        old_mom_file=old_mom_files % version
        old_mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{old_mom_file}")
        new_mom_file=old_mom_files % (version+1)
        new_mom_file="#{NSBundle.mainBundle.resourcePath}/#{new_mom_file}"
        last=false
        unless NSFileManager.defaultManager.fileExistsAtPath(new_mom_file)
          new_mom_file=_old_mom_files % "cur"
          new_mom_file="#{NSBundle.mainBundle.resourcePath}/#{new_mom_file}"
          last=true
        end
        NSLog [:migrate_from_to, old_mom_file, new_mom_file].inspect
        migrate_mom_model(old_mom_url, NSURL.fileURLWithPath(new_mom_file))
        break if last
      end
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
      NSFileManager.defaultManager.removeItemAtPath(@store_url.path, error:error_ptr)
      NSFileManager.defaultManager.moveItemAtPath(new_store_url.path, toPath:@store_url.path, error:error_ptr)
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
          migrate_model(old_mode, model)
        end
      end
    end
  
  end
end

