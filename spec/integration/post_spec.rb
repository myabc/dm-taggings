require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe 'DataMapper::Is::Taggable' do
  supported_by :all do
    require "dm-is-taggable/spec/taggable_shared_spec"
    require "#{SPEC_ROOT}/fixtures/models"

    describe "Post" do
      before(:all) { @taggable = Post }
      it_should_behave_like "A taggable resource"
    end
  end
end

