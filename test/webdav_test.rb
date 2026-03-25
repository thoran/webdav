# test/webdav_test.rb

require_relative './helper'

describe WebDAV do
  let(:base_uri){'https://dav.example.com/files/'}
  let(:username){'user'}
  let(:password){'pass'}

  let(:dav) do
    WebDAV.new(base_uri, username: username, password: password)
  end

  let(:ok_response) do
    MockResponse.new(
      code: '200',
      message: 'OK',
      body: 'Hello'
    )
  end

  let(:created_response) do
    MockResponse.new(
      code: '201',
      message: 'Created',
      body: ''
    )
  end

  let(:no_content_response) do
    MockResponse.new(
      code: '204',
      message: 'No Content',
      body: ''
    )
  end

  let(:multistatus_response) do
    MockResponse.new(
      code: '207',
      message: 'Multi-Status',
      body: <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:">
          <d:response>
            <d:href>/files/doc.txt</d:href>
            <d:propstat>
              <d:prop>
                <d:displayname>doc.txt</d:displayname>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    )
  end

  let(:not_found_response) do
    MockResponse.new(
      code: '404',
      message: 'Not Found',
      body: 'Not Found'
    )
  end

  # Properties

  describe "#propfind" do
    it "returns a MultiStatus response" do
      dav.stub(:request, multistatus_response) do
        result = dav.propfind('/')
        _(result).must_be_kind_of WebDAV::MultiStatus
        _(result.resources.length).must_equal 1
      end
    end
  end

  describe "#proppatch" do
    it "returns a MultiStatus response" do
      dav.stub(:request, multistatus_response) do
        result = dav.proppatch('/doc.txt', body: '<d:propertyupdate/>')
        _(result).must_be_kind_of WebDAV::MultiStatus
      end
    end
  end

  # Reports

  describe "#report" do
    it "returns a MultiStatus response" do
      dav.stub(:request, multistatus_response) do
        result = dav.report('/calendars/', body: '<c:calendar-query/>')
        _(result).must_be_kind_of WebDAV::MultiStatus
      end
    end
  end

  # Collections

  describe "#mkcol" do
    it "returns a Response" do
      dav.stub(:request, created_response) do
        result = dav.mkcol('/new_folder/')
        _(result).must_be_kind_of WebDAV::Response
        _(result.code).must_equal 201
      end
    end
  end

  # Namespace

  describe "#copy" do
    it "returns a Response" do
      dav.stub(:request, created_response) do
        result = dav.copy('/doc.txt', to: '/archive/doc.txt')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#move" do
    it "returns a Response" do
      dav.stub(:request, created_response) do
        result = dav.move('/draft.txt', to: '/final.txt')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  # Locking

  describe "#lock" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.lock('/doc.txt', body: '<d:lockinfo/>')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#unlock" do
    it "returns a Response" do
      dav.stub(:request, no_content_response) do
        result = dav.unlock('/doc.txt', token: 'urn:uuid:abc123')
        _(result).must_be_kind_of WebDAV::Response
        _(result.code).must_equal 204
      end
    end
  end

  # Standard HTTP

  describe "#get" do
    it "returns a Response with the body" do
      dav.stub(:request, ok_response) do
        result = dav.get('/doc.txt')
        _(result).must_be_kind_of WebDAV::Response
        _(result.body).must_equal 'Hello'
      end
    end
  end

  describe "#head" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.head('/doc.txt')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#post" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.post('/endpoint', body: '<data/>')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#put" do
    it "returns a Response" do
      dav.stub(:request, created_response) do
        result = dav.put('/doc.txt', body: 'New content', content_type: 'text/plain')
        _(result).must_be_kind_of WebDAV::Response
        _(result.code).must_equal 201
      end
    end
  end

  describe "#patch" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.patch('/doc.txt', body: '<patch/>')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#delete" do
    it "returns a Response" do
      dav.stub(:request, no_content_response) do
        result = dav.delete('/doc.txt')
        _(result).must_be_kind_of WebDAV::Response
        _(result.code).must_equal 204
      end
    end
  end

  describe "#options" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.options('/')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  describe "#trace" do
    it "returns a Response" do
      dav.stub(:request, ok_response) do
        result = dav.trace('/')
        _(result).must_be_kind_of WebDAV::Response
      end
    end
  end

  # Error handling

  describe "error responses" do
    it "raises WebDAV::Error for 404" do
      dav.stub(:request, not_found_response) do
        assert_raises(WebDAV::Error) do
          dav.get('/missing.txt')
        end
      end
    end

    it "includes the status code in the error" do
      dav.stub(:request, not_found_response) do
        error = assert_raises(WebDAV::Error){dav.get('/missing.txt')}
        _(error.code).must_equal 404
      end
    end

    it "includes the message in the error" do
      dav.stub(:request, not_found_response) do
        error = assert_raises(WebDAV::Error){dav.get('/missing.txt')}
        _(error.message).must_equal 'Not Found'
      end
    end
  end
end
