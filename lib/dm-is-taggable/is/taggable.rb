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
        def tag(tags)
          tags = [tags] unless tags.kind_of?(Array)
          
          tags.each do |tag_name|
            tag_name = Tag.build(tag_name) if tag_name.kind_of?(String)

            next if tags_collection.first(:tag_id => tag_name.id, "#{DataMapper::Inflector.underscore(self.class.to_s)}_id".intern => id)

            new_tag = tags_collection.new(:tag => tag_name)
            new_tag.save unless new?
            new_tag
          end
        end
        
        def untag(tags)
          tags = [tags] unless tags.kind_of?(Array)
          
          tags.each do |tag_name|
            tag_name = Tag.build(tag_name) if tag_name.kind_of?(String)
            tags_collection.all(:tag_id => tag_name.id).destroy
          end
        end
        
        def tags_list
          @tags_list || self.tags.collect {|t| t.name}.join(", ")
        end
        
        def tags_list=(list)
          @tags_list = list
          self.tags.each {|t| self.untag(t) }
          
          # Tag list generation
          list = list.split(",").collect {|s| s.strip}
          
          # Do the tagging here
          list.each { |t| self.tag(Tag.build(t)) }
        end

        protected

        def tags_collection
          send("#{DataMapper::Inflector.underscore(self.class.to_s)}_tags")
        end

        def tag_class
          @tag_class ||= DataMapper::Inflector.constantize("#{self.class.to_s}Tag")
        end
      end # InstanceMethods

    end # Taggable
  end # Is
end # DataMapper
