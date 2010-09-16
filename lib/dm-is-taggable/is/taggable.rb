module DataMapper
  module Is
    module Taggable

      ##
      # fired when your plugin gets included into Resource
      #
      def self.included(base)

      end

      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :example
      ##

      def is_taggable(options={})

        # Add class-methods
        extend  DataMapper::Is::Taggable::ClassMethods
        # Add instance-methods
        include DataMapper::Is::Taggable::InstanceMethods
        
        # Make the magic happen
        options[:by] ||= []

        taggable_class_name = self.to_s

        remix n, :taggings

        enhance :taggings do
          belongs_to :tag
          belongs_to DataMapper::Inflector.underscore(taggable_class_name)

          options[:by].each do |tagger_class|
            belongs_to DataMapper::Inflector.underscore(tagger_class.to_s), :required => false
          end
        end

        has n, :tags, :through => :"#{DataMapper::Inflector.underscore(self.to_s)}_tags", :constraint => :destroy

        Tag.has n, :"#{DataMapper::Inflector.underscore(self.to_s)}_tags", :constraint => :destroy
        Tag.has n, :"#{DataMapper::Inflector.underscore(self.to_s).pluralize}", :through => :"#{DataMapper::Inflector.underscore(self.to_s)}_tags", :constraint => :destroy

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
          tags = [tags] unless tags.class == Array
          
          # Transform Strings to Tags if necessary
          tags.collect!{|t| t.class == Tag ? t : Tag.first(:name => t)}.compact!
          
          # Query the objects tagged with those tags
          taggings = DataMapper::Inflector.constantize("#{self.to_s}Tag").all(:tag_id => tags.collect{|t| t.id})
          taggings.collect{|tagging| tagging.send(DataMapper::Inflector.underscore(self.to_s)) }
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
            tags_collection.new(:tag => tag)
          end

          tags_collection
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
          tags_collection = tag(tags_or_names)
          tags_collection.save! unless new?
          tags_collection
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

          tags_to_delete = if tags.blank?
            tags_collection.all
          else
            tags_collection.all(:tag => tags)
          end

          tags_collection.delete_if { |tag| tags_to_delete.include?(tag) }

          tags_to_delete
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
          tags_collection = untag(tags_or_names)
          tags_collection.destroy! unless new?
          tags_collection
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

          untag(tag_names)
          tag(tag_names)
        end

        # @api public
        def reload
          @tags_list = nil
          super
        end

        protected

        # @api semipublic
        def tags_collection
          send("#{DataMapper::Inflector.underscore(self.class.to_s)}_tags")
        end

        # @api semipublic
        def tag_class
          @tag_class ||= DataMapper::Inflector.constantize("#{self.class.to_s}Tag")
        end

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
