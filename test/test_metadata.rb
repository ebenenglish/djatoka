require 'helper'

class TestDjatokaMetadata < Test::Unit::TestCase
  with_a_resolver do
    context 'a metadata object' do
      setup do
        @metadata_obj = @resolver.metadata(@identifier)
        @metadata = @metadata_obj.perform
      end

      should 'create a metadata object' do
        assert @metadata.is_a? Djatoka::Metadata
      end

      should "create a metadata URL for an identifier" do
        assert @metadata.url.include? 'http://african.lanl.gov/adore-djatoka/resolver?'
        assert @metadata.url.include? 'url_ver=Z39.88-2004'
        assert @metadata.url.include? 'svc_id=info%3Alanl-repo%2Fsvc%2FgetMetadata'
        assert @metadata.url.include? 'rft_id=info%3Alanl-repo%2Fds%2F5aa182c2-c092-4596-af6e-e95d2e263de3'
      end

      should 'create a metadata uri for an identifier' do
        uri = @metadata.uri
        assert_equal 'african.lanl.gov', uri.host
      end

      should "return imagefile metadata for an identifier" do
        assert_equal '/lanl/data/loc/cc5fc4f7-e50a-455f-b3ce-a6a8b54824e6/WEJLNXSBWO7LPLC7Z6DITFX7A45XR3GS.jp2',
          @metadata.imagefile
      end

      should 'return an identifier for a good request' do
        assert_equal @identifier,
          @metadata.identifier
      end

      should 'return a height for a good request' do
        assert_equal '3372', @metadata.height
      end

      should 'return a width for a good request' do
        assert_equal '5120', @metadata.width
      end

      should 'return an OK status for a good request' do
        metadata = @metadata.status
      end

      should 'return a nil for a bad request' do
        metadata = @resolver.metadata('asdf')
        assert_equal nil, metadata.status
      end
    end #context metadata response

    context 'using net::http' do
      should 'return a height for a good request' do
        Djatoka.use_curb=false
        assert_equal '3372', Djatoka::Metadata.new(@resolver, @identifier).perform.height
        set_testing_curb
      end
    end

    context 'using net::https' do
      should 'get metadata when using an https URI' do
        Djatoka.use_curb=false
        resolver = Djatoka::Resolver.new('https://scrc.lib.ncsu.edu/adore-djatoka/resolver')
        metadata_obj = resolver.metadata('0004817')
        metadata = metadata_obj.perform
        assert_equal('10669', metadata.height)
      end
    end

    context 'determining all the levels for a particular metadata response' do
      setup do
        @metadata_obj = @resolver.metadata(@identifier)
        @metadata = @metadata_obj.perform
        @levels = @metadata.all_levels
      end
      should 'create the number of metadata levels as djatoka provides' do
        assert_equal 7, @levels.length
      end
      should 'return height and width for all levels' do
        expected_levels = { "0"=>{"height"=>53, "width"=>80},
                   "1"=>{"height"=>106, "width"=>160},
                   "2"=>{"height"=>211, "width"=>320},
                   "3"=>{"height"=>422, "width"=>640},
                   "4"=>{"height"=>843, "width"=>1280},
                   "5"=>{"height"=>1686, "width"=>2560},
                   "6"=>{"height"=>3372, "width"=>5120}}
        assert_equal expected_levels, @levels
      end
      should 'know which is the max level' do
        assert_equal "6", @metadata.max_level
      end

      should 'return appropriate height and width for all levels when levels and dwt_levels do not match' do
        levels = {"0"=>{"height"=>58, "width"=>37},
                  "1"=>{"height"=>115, "width"=>74},
                  "2"=>{"height"=>229, "width"=>148},
                  "3"=>{"height"=>458, "width"=>296},
                  "4"=>{"height"=>915, "width"=>592}}
        metadata = @resolver.metadata('ua023_015-006-bx0003-014-075').perform
        returned_levels = metadata.all_levels
        assert_equal levels, returned_levels

      end

    end # levels

    context 'IIIF Image Information Requests' do
      setup do
        @metadata_obj = @resolver.metadata(@identifier)
        @metadata = @metadata_obj.perform
      end

      should 'create json responses' do
        iiif_json = <<-EOF
        {
          "identifier": "info:lanl-repo/ds/5aa182c2-c092-4596-af6e-e95d2e263de3",
          "width": 5120,
          "height": 3372,
          "scale_factors": [ 0,1,2,3,4,5,6 ],
          "tile_width": 512,
          "tile_height": 512,
          "formats": [ "jpg", "png" ],
          "qualities": [ "native", "grey" ],
          "profile": "http://library.stanford.edu/iiif/image-api/compliance.html#level1",
          "image_host": "http://myserver.com/image"
        }
        EOF
        expected = JSON.parse(iiif_json)

        str = @metadata.to_iiif_json do |info|
            info.tile_width   = '512'
            info.tile_height  = 512   # tile_* can be string or int
            info.formats      = ['jpg', 'png']
            info.qualities    = ['native', 'grey']
            info.profile      = 'http://library.stanford.edu/iiif/image-api/compliance.html#level1'
            info.image_host   = 'http://myserver.com/image'
        end
        assert_equal expected, JSON.parse(str)
      end

      should 'create xml responses' do
        iiif_xml =<<-EOXML
        <info xmlns="http://library.stanford.edu/iiif/image-api/ns/">
          <identifier>info:lanl-repo/ds/5aa182c2-c092-4596-af6e-e95d2e263de3</identifier>
          <width>5120</width>
          <height>3372</height>
          <scale_factors>
            <scale_factor>0</scale_factor>
            <scale_factor>1</scale_factor>
            <scale_factor>2</scale_factor>
            <scale_factor>3</scale_factor>
            <scale_factor>4</scale_factor>
            <scale_factor>5</scale_factor>
            <scale_factor>6</scale_factor>
          </scale_factors>
          <tile_width>512</tile_width>
          <tile_height>512</tile_height>
          <formats>
            <format>jpg</format>
            <format>png</format>
          </formats>
          <qualities>
            <quality>native</quality>
            <quality>grey</quality>
          </qualities>
          <profile>http://library.stanford.edu/iiif/image-api/compliance.html#level1</profile>
          <image_host>http://myserver.com/image</image_host>
        </info>
        EOXML

        str = @metadata.to_iiif_xml do |info|
            info.tile_width   = '512'
            info.tile_height  = 512   # tile_* can be string or int
            info.formats      = ['jpg', 'png']
            info.qualities    = ['native', 'grey']
            info.profile      = 'http://library.stanford.edu/iiif/image-api/compliance.html#level1'
            info.image_host   = 'http://myserver.com/image'
        end
        assert EquivalentXml.equivalent?(str, iiif_xml)
      end
    end #IIIF Info Responses

  end #with_a_resolver

end
