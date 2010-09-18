module Tagging
  include DataMapper::Resource

  property :id, Serial
  property :tag_id, Integer, :min => 1, :required => true

  is :remixable, :suffix => "tag"

  def tagger=(tagger)
    send("#{DataMapper::Inflector.underscore(tagger.class.name).to_sym}=", tagger)
  end
end

