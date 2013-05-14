# DbMotion

Simple CoreData Adapter for RubyMotion

## Getting Started

### Create a MOM CoreData Model
Create a XCode "Empty Project" add there a CoreData Model.


### Adding DbMotion to your RubyMotion project

in Gemfile
`gem 'DbMotion'`
then run `bundle update`

Load model info from MOM (as of version 1) or define it directly as in version 2.
Version 1 models would be automaticly updated to version 2.
```ruby
class TestModel < DbMotion::Model
  
  version(1) do |db|
    db.mom_file "Test_001.mom"
  end
  
  version(2) do |db|
    db.entity("Object1") do |obj1|
      obj1.string  :name
      obj1.date    :lastvisit
    end
    
    db.entity("Object2") do |obj2|
      obj2.string :name
    end
	
	db.relation "Object1:objects2 <<->> Object2:objects1"
  end
end
```

in AppDelegate add the following to open the specified Database:
```ruby
dbm=DbMotion::Database.new.open("MyCoreData.sqlite", TestModel)
DbMotion::Database.setSharedSession(dbm)
```

Search for Items in the Database:
```ruby
items=DbMotion::Database.shared.find_entry("Object1")
```

Save something in the Database:
```ruby
item=DbMotion::Database.shared.create_entry("Object2")
item.name=form[:name]
if DbMotion::Database.shared.save
  # item saved
end
```
