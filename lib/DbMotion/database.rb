module DbMotion
class Database
  
  def self.run
    @@db
  end
  
  def create_entry(_name)
    NSEntityDescription.insertNewObjectForEntityForName(_name, inManagedObjectContext:@context)
  end
  
  def find_entry(_name)
    request = NSFetchRequest.alloc.init
    request.entity = NSEntityDescription.entityForName(_name, inManagedObjectContext:@context)
    #request.sortDescriptors = [NSSortDescriptor.alloc.initWithKey('creation_date', ascending:false)] 
    error_ptr = Pointer.new(:object)
    @context.executeFetchRequest(request, error:error_ptr)
  end
  
  def save
    error_ptr = Pointer.new(:object)
    @context.save(error_ptr)
  end
  
  def open(_mom_file, _db_file)
    @mom_file=_mom_file % "cur"
    @mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{@mom_file}")
    @model=NSManagedObjectModel.alloc.initWithContentsOfURL(@mom_url)
    @store = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model)
    @store_file = File.join(NSHomeDirectory(), 'Documents', _db_file)
    @store_url  = NSURL.fileURLWithPath(@store_file)
    unless compatible?
      migrate(_mom_file)
    end
    @context = NSManagedObjectContext.alloc.init
    @context.persistentStoreCoordinator = @store
    error_ptr = Pointer.new(:object)
    unless @store.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:@store_url, options:nil, error:error_ptr)
      raise "Can't add persistent SQLite store: #{error_ptr[0].description}"
    end
    @@db=self
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
  
  def migrate(_old_mom_files)
    old_mom_files=_old_mom_files % '%03d'
    error_ptr = Pointer.new(:object)
    metadata=NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL:@store_url, error:error_ptr)
    return false unless metadata
    0.upto(999) do |version|
      old_mom_file=old_mom_files % version
      p old_mom_file
      old_mom_url = NSURL.fileURLWithPath("#{NSBundle.mainBundle.resourcePath}/#{old_mom_file}")
      p old_mom_url
      old_model=NSManagedObjectModel.alloc.initWithContentsOfURL(old_mom_url)
      compatible=old_model.isConfiguration(nil, compatibleWithStoreMetadata:metadata)
      next unless compatible
      p "Found version #{version}"
      migmgr=NSMigrationManager.alloc.initWithSourceModel(old_model, destinationModel:@model)
      mapping_model = NSMappingModel.inferredMappingModelForSourceModel(old_model, destinationModel:@model, error:error_ptr)
      new_store_url = NSURL.fileURLWithPath(@store_url.path+".new")
      p migmgr.migrateStoreFromURL(@store_url, type:NSSQLiteStoreType, options:nil,
                                withMappingModel:mapping_model, toDestinationURL:new_store_url,
                                destinationType:NSSQLiteStoreType, destinationOptions:nil,
                                error:error_ptr)
      NSFileManager.defaultManager.removeItemAtPath(@store_url.path, error:error_ptr)
      #-TODO: evtl. move statt loeschen
      NSFileManager.defaultManager.moveItemAtPath(new_store_url.path, toPath:@store_url.path, error:error_ptr)
      break
    end
  end
  
end
end

