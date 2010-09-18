module DataMapper
  module Is
    module Tagger
      # Set up a resource as tagger
      #
      # @api public
      def is_tagger(options={})
        unless self.respond_to?(:tagger?)
          # Add class-methods
          extend  DataMapper::Is::Tagger::ClassMethods

          # Add instance-methods
          include DataMapper::Is::Tagger::InstanceMethods

          cattr_accessor(:taggable_object_classes)
          self.taggable_object_classes = []
        end

        raise "options[:for] is missing" unless options[:for]

        add_taggable_object_classes(options[:for])
      end

      module ClassMethods
        def tagger?
          true
        end

        def add_taggable_object_classes(taggable_object_classes)
          taggable_object_classes.each do |taggable_object_class|
            self.taggable_object_classes << taggable_object_class

            has n, taggable_object_class.tagging_relationship_name,
              :constraint => :destroy

            has n, taggable_object_class.taggable_relationship_name,
              :through => taggable_object_class.tagging_relationship_name,
              :constraint => :destroy
          end
        end
      end # ClassMethods

      module InstanceMethods
        def tag!(taggable, options={})
          unless self.taggable_object_classes.include?(taggable.class)
            raise "Object of type #{taggable.class} isn't taggable!"
          end

          tags = options[:with]
          tags = [tags] unless tags.kind_of?(Array)

          tags.each do |tag|
            taggable.taggings.create(:tag => tag, :tagger => self)
          end

          tags
        end
      end # InstanceMethods

    end # Tagger
  end # Is
end # DataMapper

