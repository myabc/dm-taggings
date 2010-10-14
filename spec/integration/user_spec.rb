require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe 'DataMapper::Is::Taggable' do
  supported_by :all do
    require "dm-taggings/spec/tagger_shared_spec"

    describe User do
      before(:all) do
        @tagger   = User
        @taggable = Book
      end

      it_should_behave_like "A tagger resource"
    end
  end
end

