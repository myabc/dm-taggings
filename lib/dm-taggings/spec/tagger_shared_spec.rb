share_examples_for 'A tagger resource' do
  before :all do
    %w[ @tagger @taggable ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_defined?(ivar)
    end

    @foo_tag  = Tag["foo"]
    @bar_tag  = Tag["bar"]

    @tags = [@foo_tag, @bar_tag]
  end

  subject { @tagger }

  [ :is_tagger, :tagger?, :add_taggable_object_classes, :taggable_object_classes ].each do |method|
    it { should respond_to(method) }
  end

  describe ".tagger?" do
    subject { @tagger.tagger? }
    it { should be(true) }
  end

  describe "#tag!" do
    before :all do
      @tagger_resource   = @tagger.create
      @taggable_resource = @taggable.create

      @tags = @tagger_resource.tag!(@taggable_resource, :with => @tags)
    end

    it "should tag the taggable resource" do
      @taggable_resource.tags.should include(*@tags)
    end

    it "should associate tagger with taggable" do
      @tagger_resource.reload.send(DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(@taggable.name)).pluralize).should include(@taggable_resource)
    end

    it "should associate taggings with tagger" do
      @taggable_resource.taggings.each do |tagging|
        tagging.send(DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(@tagger.name))).should eql(@tagger_resource)
      end
    end
  end
end

