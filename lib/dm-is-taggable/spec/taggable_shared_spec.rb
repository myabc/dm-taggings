share_examples_for 'A taggable resource' do
  before :all do
    %w[ @taggable ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
    end

    @foo_tag  = Tag["foo"]
    @bar_tag  = Tag["bar"]

    @tags = [@foo_tag, @bar_tag]
  end

  describe "public class methods" do
    subject { @taggable }

    it { should respond_to(:is_taggable) }
    it { should respond_to(:taggable?) }
    it { should respond_to(:tagged_with) }
    it { should respond_to(:tagging_relationship_name) }
    it { should respond_to(:tagging_relationship) }
    it { should respond_to(:tagging_class) }


    describe ".taggable?" do
      it "should return true" do
        @taggable.taggable?.should be(true)
      end
    end

    describe "relationships" do
      subject { @taggable.relationships }

      it { should have_key(@taggable.tagging_relationship_name) }

      describe "tagging constraint" do
        subject { @taggable.tagging_relationship.constraint }
        it { subject.should eql(:destroy!) }
      end
    end
  end

  describe "public instance methods" do
    subject { @taggable.new }

    it { should respond_to(:tag) }
    it { should respond_to(:tag!) }
    it { should respond_to(:untag) }
    it { should respond_to(:untag!) }
    it { should respond_to(:tags_list) }
    it { should respond_to(:taggings_collection) }

    describe ".tag" do
      before :all do
        @resource = @taggable.create
        @taggings = @resource.tag([@foo_tag, @bar_tag])
      end

      it "should set new taggings" do
        @taggings.should eql(@resource.taggings_collection)
      end

      it "should not create new taggings" do
        @resource.tags.should be_empty
      end
    end

    describe ".tag!" do
      before :all do
        @resource = @taggable.create
        @taggings = @resource.tag!([@foo_tag, @bar_tag])
      end

      it "should create new taggings" do
        @resource.reload.tags.should include(@foo_tag, @bar_tag)
      end
    end

    describe ".untag" do
      before :all do
        @resource = @taggable.create
        @taggings = @resource.tag!([@foo_tag, @bar_tag])
        @resource.untag([@foo_tag, @bar_tag])
      end

      it "should remove the taggings" do
        @resource.taggings_collection.should be_empty
      end

      it "should not destroy the taggings" do
        @resource.reload.taggings_collection.should_not be_empty
      end
    end

    describe ".untag!" do
      before :all do
        @resource = @taggable.create
        @taggings = @resource.tag!([@foo_tag, @bar_tag])
        @resource.untag([@foo_tag, @bar_tag])
      end

      it "should destroy the taggings" do
        @resource.reload.taggings_collection.should_not be_empty
      end

      it "should not destroy the tags" do
        Tag.all.should include(*@tags)
      end
    end

    describe ".tags_list=" do
      before :all do
        @tag_names = %w(red green blue)
        @resource  = @taggable.create(:tags_list => @tag_names.join(', '))
      end

      it "should set the taggings" do
        @resource.reload.tags.should include(*Tag.all(:name => @tag_names))
      end
    end
  end
end

