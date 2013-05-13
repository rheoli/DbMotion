# DbMotion

Simple CoreData Adapter for RubyMotion

## Getting Started

### Create a MOM CoreData Model
Create a XCode "Empty Project" add there a CoreData Model.


### Adding DbMotion to your RubyMotion project

in Gemfile
`gem 'DbMotion'`
then run `bundle update`

in AppDelegate add the following to open the specified Database:
```ruby
dbm=DbMotion::Database.new.open("MyCoreData.sqlite", withMOMFile: "MyCoreDataModel_%s.mom")
DbMotion::Database.setSharedSession(dbm)
```

Search for Items in the Database:
```ruby
items=DbMotion::Database.shared.find_entry("Item")
```

Save something in the Database:
```ruby
item=DbMotion::Database.shared.create_entry("Item")
item.name=form[:name]
if DbMotion::Database.shared.save
  # item saved
end
```
