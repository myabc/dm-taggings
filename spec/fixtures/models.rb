class Post
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :description, Text

  is :taggable
end

class User
  include DataMapper::Resource

  property :id, Serial
  property :login, String
end

class Book
  include DataMapper::Resource

  property :id, Serial
  property :isbn, String, :length => 13, :required => true, :default => "123412"
  property :title, String, :required => true, :default => "Hobbit"
  property :author, String

  is :taggable, :by => [User]
end

class Song
  include DataMapper::Resource

  property :id, Serial
  is :taggable
end

module BigVendor
  module ContentManagement
    class Account
      include DataMapper::Resource

      property :id,     Serial
      property :login,  String
    end

    class ContentBlock
      include DataMapper::Resource

      property :id,           Serial
      property :name,         String
      property :description,  Text

      is :taggable, :by => [::BigVendor::ContentManagement::Account]
    end
  end
end
