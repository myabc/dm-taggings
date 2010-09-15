require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe 'Tag' do
  supported_by :all do
    require "#{SPEC_ROOT}/fixtures/models"

    it "should have id and name columns" do
      [:id, :name].each do |property_name|
        Tag.properties[property_name].should_not be_nil
      end
    end

    describe "#strip_name" do
      before { @tag = Tag.new }

      it "should strip the tag name" do
        @tag.name = "blue "
        @tag.save
        @tag.name.should == "blue"
        second_tag = Tag.build("blue ")
        second_tag.should == @tag
      end
    end
  end
end
