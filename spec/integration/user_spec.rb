require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe 'DataMapper::Is::Taggable' do
  supported_by :all do
    require "dm-is-taggable/spec/tagger_shared_spec"
    require "#{SPEC_ROOT}/fixtures/models"

    describe User do
      before(:all) do
        @tagger   = User
        @taggable = Book
      end

      it_should_behave_like "A tagger resource"
    end
  end
end

