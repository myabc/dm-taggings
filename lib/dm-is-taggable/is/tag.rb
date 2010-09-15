class Tag
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :required => true, :unique => true

  def self.[](name)
    build(name)
  end

  def self.build(name)
    Tag.first_or_create(:name => name.strip) if name
  end

  def name=(value)
    super(value.strip) if value
    name
  end
end
