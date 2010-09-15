begin
  # Just in case the bundle was locked
  # This shouldn't happen in a dev environment but lets be safe
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

Bundler.require(:default, :development)


begin

  require 'rake'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|

    gem.name        = 'dm-is-taggable'
    gem.summary     = 'Tagging plugin for DataMapper'
    gem.description = 'DataMapper plugin that adds the possibility to tag models'
    gem.email       = 'piotr.solnica@gmail.com'
    gem.homepage    = 'http://github.com/solnic/dm-is-taggable'
    gem.authors     = [ 'Maxime Guilbot', 'Martin Gamsjaeger (snusnu)', 'Piotr Solnica' ]

    gem.add_dependency 'dm-core',           '~> 1.0.2'
    gem.add_dependency 'dm-constraints',    '~> 1.0.2'
    gem.add_dependency 'dm-is-remixable',   '~> 1.0.2'

    gem.add_development_dependency 'rspec', '~> 1.3'
    gem.add_development_dependency 'yard',  '~> 0.5'

  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }

rescue LoadError => e
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
  puts e.message
  puts e.backtrace
end
