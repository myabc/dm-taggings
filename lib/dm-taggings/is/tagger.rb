module DataMapper
  module Is
    module Tagger
      # Set up a resource as tagger
      #
      # @example
      #
      #   class Song
      #     include DataMapper::Resource
      #
      #     property :id,    Serial
      #     property :title, String
      #
      #     is :taggable, :by => [ User ]
      #   end
      #
      #   class User
      #     include DataMapper::Resource
      #
      #     property :id,   Serial
      #     property :name, String
      #
      #     is :tagger, :for => [ Song ]
      #   end
      #
      # @param [Hash] options
      #   A hash of options
      # @option options [Array] :for
      #   A list of DataMapper taggable models
      #
      # @return [Array]
      #   A list of DataMapper taggable models
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
        # Return if a model is tagger
        #
        # @return [TrueClass]
        #   true
        #
        # @api public
        def tagger?
          true
        end

        # Register new taggables and set up relationships
        #
        # @param [Array] taggable_object_classes
        #   An array of taggable DataMapper models
        #
        # @api public
        def add_taggable_object_classes(taggable_object_classes)
          taggable_object_classes.each do |taggable_object_class|
            self.taggable_object_classes << taggable_object_class

            has n, taggable_object_class.tagging_relationship_name,
              :model      => taggable_object_class.tagging_class,
              :constraint => :destroy

            has n, taggable_object_class.taggable_relationship_name,
              :model      => taggable_object_class.name,
              :through    => taggable_object_class.tagging_relationship_name,
              :constraint => :destroy
          end
        end
      end # ClassMethods

      module InstanceMethods
        # Tag a resource
        #
        # @param [DataMapper::Resource]
        #   An instance of a taggable resource
        #
        # @param [Hash] options (optional)
        #   A hash with options
        #
        # @return [DataMapper::Collection]
        #  A collection of tags that were associated with the resource
        #
        # @api public
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
