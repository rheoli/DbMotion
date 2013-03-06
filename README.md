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
DbMotion::Database.new.open("MyCoreDataModel_%s.mom", "MyCoreData.sqlite")
```

Search for Items in the Database:
```ruby
items=DbMotion::Database.run.find_entry("Item")
```

Save something in the Database:
```ruby
item=DbMotion::Database.run.create_entry("Item")
item.name=form[:name]
if DbMotion::Database.run.save
  # item saved
end
```
