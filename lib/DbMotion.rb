unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

require "DbMotion/version"

Motion::Project::App.setup do |app|
  app.files = Dir.glob(File.join(File.dirname(__FILE__), 'DbMotion/**/*.rb')) | app.files
  app.frameworks += ['CoreData']
end

