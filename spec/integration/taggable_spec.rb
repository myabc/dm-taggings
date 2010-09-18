require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe DataMapper::Is::Taggable do
  supported_by :all do
    describe Song do
      describe ".is_taggable" do
        describe "taggings relationship" do
          subject { Song.relationships[:song_tags] }

          it { should be_kind_of(DataMapper::Associations::OneToMany::Relationship) }
        end

        describe "remixed tagging" do
          before :all do
            begin
              @tagging = SongTag
            rescue; end
          end

          it "should belong to taggable" do
            @tagging.relationships[:song].should be_kind_of(DataMapper::Associations::ManyToOne::Relationship)
          end
        end

        describe Tag do
          it "should have new taggings relationship" do
            Tag.relationships[:song_tags].should be_kind_of(DataMapper::Associations::OneToMany::Relationship)
          end

          it "should have new taggable relationship" do
            Tag.relationships[:songs].should be_kind_of(DataMapper::Associations::ManyToMany::Relationship)
          end
        end
      end
    end
  end
end

