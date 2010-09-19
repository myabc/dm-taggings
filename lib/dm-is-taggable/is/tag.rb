class Tag
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :required => true, :unique => true

  # Shortcut to build method
  #
  # @see Tag.build
  #
  # @api public
  def self.[](name)
    build(name)
  end

  # Find or create a tag with the give name
  #
  # @param [String] name
  #   A name of a tag
  #
  # @return [DataMapper::Resource]
  #   A tag resource instance
  #
  # @api public
  def self.build(name)
    Tag.first_or_create(:name => name.strip) if name
  end

  # An overridden name attribute setter that strips the value
  #
  # @param [String] value
  #   A value to be set as the tag name
  #
  # @return [String]
  #  The name
  #
  # @api public
  def name=(value)
    super(value.strip) if value
    name
  end
end
