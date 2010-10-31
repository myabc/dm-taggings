module DataMapper
  module Is
    module Taggable

      # Make a resource taggable
      #
      # @example
      #
      #   class Post
      #     include DataMapper::Resource
      #
      #     property :id,      Serial
      #     property :title,   String
      #     property :content, Text
      #
      #     is :taggable
      #   end
      #
      # @param [Hash] options(optional)
      #   A hash with options
      # @option options [Array] :by
      #   A list of DataMapper models that should become taggers
      #
      # @api public
      def is_taggable(options={})

        # Add class-methods
        extend  DataMapper::Is::Taggable::ClassMethods
        # Add instance-methods
        include DataMapper::Is::Taggable::InstanceMethods

        class << self
          attr_reader :tagging_parent_name, :tagging_relationship_name, :tagging_relationship,
            :tagging_class, :taggable_relationship_name
        end

        # Make the magic happen
        options[:by] ||= []

        remix n, :taggings

        @tagging_parent_name       = DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(name)).to_sym
        @tagging_relationship_name = "#{@tagging_parent_name}_tags".to_sym
        @tagging_relationship      = relationships[@tagging_relationship_name]
        @tagging_class             = @tagging_relationship.child_model

        @taggable_relationship_name = DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(name)).pluralize.to_sym

        @tagging_relationship.add_constraint_option(
          @taggable_relationship_name, @tagging_class, self, :constraint => :destroy!)

        tagging_parent_name = @tagging_parent_name

        enhance :taggings do
          belongs_to :tag
          belongs_to tagging_parent_name, name

          options[:by].each do |tagger_class|
            belongs_to DataMapper::Inflector.underscore(DataMapper::Inflector.demodulize(tagger_class.name)), tagger_class.name, :required => false
          end
        end

        has n, :tags, :through => @tagging_relationship_name, :constraint => :destroy!

        Tag.has n, @tagging_relationship_name,  :model => tagging_class, :constraint => :destroy!
        Tag.has n, @taggable_relationship_name, :model => name, :through => @tagging_relationship_name

        options[:by].each do |tagger_class|
          tagger_class.is :tagger, :for => [self]
        end
      end

      module ClassMethods
        # @attr_reader [String] tagging_parent_name
        # @attr_reader [String] tagging_relationship_name
        # @attr_reader [DataMapper::Associations::OneToMany::Relationship] tagging_relationship
        # @attr_reader [DataMapper::Resource] tagging_class
        # @attr_reader [String] taggable_relationship_name

        # @api public
        def taggable?
          true
        end

        # Return all the taggable resources that are tagged with the given list of tags.
        #
        # Can be chained, for instance:
        #
        #     Post.tagged_with(["foo", "bar"]).all(:created_at.lt => 1.day.ago)
        #
        # @param [Array] tags_or_names
        #   A list of either tag resources or tag names
        #
        # @return [DataMapper::Collection]
        #   A collection of taggables
        #
        # @api public
        def tagged_with(tags_or_names)
          tags_or_names = [tags_or_names] unless tags_or_names.kind_of?(Array)

          tag_ids = if tags_or_names.all? { |tag| tag.kind_of?(Tag) }
                   tags_or_names
                 else
                   Tag.all(:name => tags_or_names)
                 end.map { |tag| tag.id }

          all("#{tagging_relationship_name}.tag_id" => tag_ids)
        end
      end # ClassMethods

      module InstanceMethods
        # Add tags to a resource but do not persist them.
        #
        # @param [Array] tags_or_names
        #   A list of either tag resources or tag names
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        #
        # @api public
        def tag(tags_or_names)
          tags = extract_tags_from_names(tags_or_names)

          tags.each do |tag|
            next if self.tags.include?(tag)
            taggings.new(:tag => tag)
          end

          taggings
        end

        # Add tags to a resource and persists them.
        #
        # @param [Array] tags_or_names
        #   A list of either tag resources or tag names
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        #
        # @api public
        def tag!(tags_or_names)
          taggings = tag(tags_or_names)
          taggings.save! unless new?
          taggings
        end

        # Delete given tags from a resource collection without actually deleting
        # them from the datastore. Everything will be deleted if no tags are given.
        #
        # @param [Array] tags_or_names (optional)
        #   A list of either tag resources or tag names
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        #
        # @api public
        def untag(tags_or_names=nil)
          tags = extract_tags_from_names(tags_or_names) if tags_or_names

          taggings_to_destroy = if tags.blank?
                             taggings.all
                           else
                             taggings.all(:tag => tags)
                           end

          self.taggings = taggings - taggings_to_destroy

          taggings_to_destroy
        end

        # Same as untag but actually delete the tags from the datastore.
        #
        # @param [Array] tags_or_names (optional)
        #   A list of either tag resources or tag names
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        #
        # @api public
        def untag!(tags_or_names=nil)
          taggings_to_destroy = untag(tags_or_names)
          taggings_to_destroy.destroy! unless new?
          taggings_to_destroy
        end

        # Return a string representation of tags collection
        #
        # @return [String]
        #   A tag list separated by commas
        #
        # @api public
        def tag_list
          @tag_list ||= tags.collect { |tag| tag.name }.join(", ")
        end

        # Tag a resource using tag names from the give list separated by commas.
        #
        # @param [String]
        #   A tag list separated by commas
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        def tag_list=(list)
          @tag_list = list

          tag_names = list.split(",").map { |name| name.blank? ? nil : name.strip }.compact

          old_tag_names = taggings.map { |tagging| tagging.tag.name } - tag_names

          untag!(old_tag_names)
          tag(tag_names)
        end

        # @api public
        def reload
          @tag_list = nil
          super
        end

        # @api public
        def taggings
          send(self.class.tagging_relationship_name)
        end

        # @api public
        def taggings=(taggings)
          send("#{self.class.tagging_relationship_name}=", taggings)
        end

        protected

        # @api private
        def extract_tags_from_names(tags_or_names)
          tags_or_names = [tags_or_names] unless tags_or_names.kind_of?(Array)

          tags_or_names.map do |tag_or_name|
            tag_or_name.kind_of?(Tag) ? tag_or_name : Tag[tag_or_name]
          end
        end
      end # InstanceMethods

    end # Taggable
  end # Is
end # DataMapper

