# test/WebDAV/MultiStatus_test.rb

require_relative '../helper'

describe WebDAV::MultiStatus do
  let(:multistatus_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:">
        <d:response>
          <d:href>/dav/calendars/user/test/calendar1/</d:href>
          <d:propstat>
            <d:prop>
              <d:displayname>Work</d:displayname>
              <d:resourcetype><d:collection/></d:resourcetype>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/dav/calendars/user/test/calendar2/</d:href>
          <d:propstat>
            <d:prop>
              <d:displayname>Personal</d:displayname>
              <d:resourcetype><d:collection/></d:resourcetype>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end

  let(:mock_response) do
    MockResponse.new(
      code: '207',
      message: 'Multi-Status',
      body: multistatus_xml
    )
  end

  let(:response){WebDAV::MultiStatus.new(mock_response)}

  describe "#code" do
    it "returns 207" do
      _(response.code).must_equal 207
    end
  end

  describe "#success?" do
    it "returns true" do
      _(response.success?).must_equal true
    end
  end

  describe "#resources" do
    it "returns an array" do
      _(response.resources).must_be_kind_of Array
    end

    it "parses the correct number of resources" do
      _(response.resources.length).must_equal 2
    end

    it "extracts href from each resource" do
      _(response.resources[0][:href]).must_equal '/dav/calendars/user/test/calendar1/'
      _(response.resources[1][:href]).must_equal '/dav/calendars/user/test/calendar2/'
    end

    it "extracts properties from each resource" do
      _(response.resources[0][:properties]['displayname']).must_equal 'Work'
      _(response.resources[1][:properties]['displayname']).must_equal 'Personal'
    end

    it "extracts status from each resource" do
      _(response.resources[0][:status]).must_equal 'HTTP/1.1 200 OK'
    end
  end

  describe "with empty multistatus" do
    let(:empty_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:">
        </d:multistatus>
      XML
    end

    let(:empty_response) do
      MockResponse.new(
        code: '207',
        message: 'Multi-Status',
        body: empty_xml
      )
    end

    it "returns an empty array" do
      r = WebDAV::MultiStatus.new(empty_response)
      _(r.resources).must_equal []
    end
  end
end
