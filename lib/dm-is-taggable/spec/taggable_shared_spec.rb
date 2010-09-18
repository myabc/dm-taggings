share_examples_for 'A taggable resource' do
  def create_taggable(attrs={})
    @taggable.create(@taggable_attributes.merge(attrs))
  end

  before :all do
    %w[ @taggable ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
    end

    @taggable_attributes ||= {}

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
    it { should respond_to(:tagging_parent_name) }
    it { should respond_to(:taggable_relationship_name) }

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
    it { should respond_to(:taggings) }

    describe ".tag" do
      before :all do
        @resource = create_taggable
        @taggings = @resource.tag([@foo_tag, @bar_tag])
      end

      it "should set new taggings" do
        @taggings.should eql(@resource.taggings)
      end

      it "should not create new taggings" do
        @resource.tags.should be_empty
      end
    end

    describe ".tag!" do
      before :all do
        @resource = create_taggable
        @taggings = @resource.tag!([@foo_tag, @bar_tag])
      end

      it "should create new taggings" do
        @resource.reload.tags.should include(@foo_tag, @bar_tag)
      end
    end

    describe ".untag" do
      describe "all" do
        before :all do
          @resource = create_taggable
          @taggings = @resource.tag!([@foo_tag, @bar_tag])

          @resource.untag
        end

        it "should remove the taggings from the collection" do
          @resource.taggings.should be_empty
        end

        it "should not destroy the taggings" do
          @resource.reload.tags.should_not be_empty
        end
      end

      describe "specific names" do
        before :all do
          @resource = create_taggable
          @taggings = @resource.tag!([@foo_tag, @bar_tag])

          @resource.untag([@foo_tag])
        end

        it "should remove the related tagging from the collection" do
          @resource.taggings.size.should eql(1)
        end

        it "should remove the related tag" do
          @resource.tags.should_not include(@foo_tag)
        end
      end

      describe "when save is called" do
        before :all do
          @resource = create_taggable
          @taggings = @resource.tag!([@foo_tag, @bar_tag])

          @resource.untag
        end

        it "should return true" do
          pending "Currently DataMapper doesn't support saving an empty collection" do
            @resource.save.should be(true)
          end
        end

        it "should destroy taggings" do
          pending "Currently DataMapper doesn't support saving an empty collection" do
            @resource.reload.taggings.should be_empty
          end
        end

        it "should destroy tags" do
          pending "Currently DataMapper doesn't support saving an empty collection" do
            @resource.reload.tags.should be_empty
          end
        end
      end
    end

    describe ".untag!" do
      describe "all" do
        before :all do
          @resource = create_taggable
          @taggings = @resource.tag!([@foo_tag, @bar_tag])

          @resource.untag!
        end

        it "should destroy the taggings" do
          @resource.reload.taggings.should be_empty
        end
      end

      describe "specific names" do
        before :all do
          @resource = create_taggable
          @taggings = @resource.tag!([@foo_tag, @bar_tag])

          @resource.untag!([@foo_tag])
          @resource.reload
        end

        subject { @resource.tags }

        it { should_not include(@foo_tag) }
        it { should include(@bar_tag) }
      end
    end

    describe ".tags_list=" do
      describe "with a list of tag names" do
        describe "with blank values" do
          before :all do
            @resource = create_taggable(:tags_list => "foo, , ,bar, , ")
          end

          it "should add new tags and reject blank names" do
            @resource.reload.tags.should include(Tag["foo"], Tag["bar"])
          end
        end

        describe "when tags are removed and added" do
          before :all do
            @resource = create_taggable(:tags_list => "foo, bar")
            @resource.update(:tags_list => "foo, bar, pub")
          end

          it "should add new tags" do
            @resource.reload.tags.should include(Tag["bar"], Tag["bar"], Tag["pub"])
          end
        end

        describe "when tags are added" do
          before :all do
            @resource = create_taggable(:tags_list => "foo, bar")
            @resource.update(:tags_list => "bar, pub")
          end

          it "should add new tags" do
            @resource.reload.tags.should include(Tag["bar"], Tag["pub"])
          end

          it "should remove tags" do
            @resource.reload.tags.should_not include(Tag["foo"])
          end
        end
      end

      describe "when no list of tag names is given" do
        before :all do
          @resource = create_taggable(:tags_list => "foo, bar")
          @resource.update(:tags_list => "")
        end

        it "should destroy taggings" do
          @resource.reload.taggings.should be_blank
        end

        it "should remove the tags" do
          @resource.reload.tags.should be_blank
        end
      end
    end

    describe ".tags_list" do
      before :all do
        @tag_names = %w(red green blue)
        @expected  = @tag_names.join(', ')
        @resource  = create_taggable(:tags_list => @expected)
      end

      it "should return the list of tag names" do
        @resource.tags_list.should eql(@expected)
      end
    end
  end
end

