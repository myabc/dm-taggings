require 'dm-core/spec/setup'
require 'dm-core/spec/lib/adapter_helpers'

require 'dm-validations'
require 'dm-taggings'

SPEC_ROOT = Pathname(__FILE__).dirname

DataMapper::Spec.setup

require "#{SPEC_ROOT}/fixtures/models"

DataMapper.finalize

RSpec.configure do |config|
  config.extend(DataMapper::Spec::Adapters::Helpers)

  config.before :suite do
    DataMapper.auto_migrate!
  end
end
