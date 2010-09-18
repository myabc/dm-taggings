module DataMapper
  module Is
    module Taggable

      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :taggable
      ##

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

        @tagging_parent_name       = DataMapper::Inflector.underscore(name).to_sym
        @tagging_relationship_name = "#{@tagging_parent_name}_tags".to_sym
        @tagging_relationship      = relationships[@tagging_relationship_name]
        @tagging_class             = @tagging_relationship.child_model

        @taggable_relationship_name = DataMapper::Inflector.underscore(name).pluralize.to_sym

        @tagging_relationship.add_constraint_option(
          @taggable_relationship_name, @tagging_class, self, :constraint => :destroy!)

        tagging_parent_name = @tagging_parent_name

        enhance :taggings do
          belongs_to :tag
          belongs_to tagging_parent_name

          options[:by].each do |tagger_class|
            belongs_to DataMapper::Inflector.underscore(tagger_class.name), :required => false
          end
        end

        has n, :tags, :through => @tagging_relationship_name, :constraint => :destroy!

        Tag.has n, @tagging_relationship_name,  :constraint => :destroy!
        Tag.has n, @taggable_relationship_name, :through => @tagging_relationship_name

        options[:by].each do |tagger_class|
          tagger_class.is :tagger, :for => [self]
        end
      end

      module ClassMethods
        def taggable?
          true
        end

        def tagged_with(tags)
          # tags can be an object or an array
          tags = [tags] unless tags.kind_of?(Array)

          # Transform Strings to Tags if necessary
          tags.collect! { |tag|
            tag.kind_of?(Tag) ? tag : Tag.first(:name => tag) }.compact!

          # Query the objects tagged with those tags
          tagging_class.all(:tag => tags).send(tagging_parent_name)
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
        def tags_list
          @tags_list ||= tags.collect { |tag| tag.name }.join(", ")
        end

        # Tag a resource using tag names from the give list separated by commas.
        #
        # @param [String]
        #   A tag list separated by commas
        #
        # @return [DataMapper::Associations::OneToMany::Collection]
        #   A DataMapper collection of resource's tags
        def tags_list=(list)
          @tags_list = list

          tag_names = list.split(",").each { |name| name.strip! }

          cur_tag_names = taggings.map { |tagging| tagging.tag.name }
          new_tag_names = tag_names - cur_tag_names
          old_tag_names = cur_tag_names - tag_names

          untag!(old_tag_names)
          tag(new_tag_names)
        end

        # @api public
        def reload
          @tags_list = nil
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

