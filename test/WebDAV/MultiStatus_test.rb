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

    it "extracts properties from each propstat, keyed by namespace then local name" do
      _(response.resources[0][:propstats][0][:properties]['DAV:']['displayname']).must_equal 'Work'
      _(response.resources[1][:propstats][0][:properties]['DAV:']['displayname']).must_equal 'Personal'
    end

    it "extracts per-propstat status" do
      _(response.resources[0][:propstats][0][:status]).must_equal 'HTTP/1.1 200 OK'
    end

    it "leaves response-level status nil when propstats are present" do
      _(response.resources[0][:status]).must_be_nil
    end
  end

  describe "with multiple propstats per response" do
    let(:mixed_status_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:">
          <d:response>
            <d:href>/calendar/</d:href>
            <d:propstat>
              <d:prop>
                <d:displayname>Work</d:displayname>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
            <d:propstat>
              <d:prop>
                <d:getctag/>
              </d:prop>
              <d:status>HTTP/1.1 404 Not Found</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    let(:mixed_response){WebDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: mixed_status_xml))}

    it "preserves each propstat as a separate entry" do
      _(mixed_response.resources[0][:propstats].length).must_equal 2
    end

    it "keeps the 200 propstat's properties under its own status" do
      successful_propstat = mixed_response.resources[0][:propstats][0]
      _(successful_propstat[:status]).must_equal 'HTTP/1.1 200 OK'
      _(successful_propstat[:properties]['DAV:']['displayname']).must_equal 'Work'
    end

    it "keeps the 404 propstat's properties under its own status" do
      missing_propstat = mixed_response.resources[0][:propstats][1]
      _(missing_propstat[:status]).must_equal 'HTTP/1.1 404 Not Found'
      _(missing_propstat[:properties]['DAV:']).must_include 'getctag'
    end
  end

  describe "with response-level status (COPY/MOVE/DELETE)" do
    let(:response_level_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:">
          <d:response>
            <d:href>/dir/file.txt</d:href>
            <d:status>HTTP/1.1 403 Forbidden</d:status>
          </d:response>
        </d:multistatus>
      XML
    end

    let(:response_level_response){WebDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: response_level_xml))}

    it "populates the response-level status" do
      _(response_level_response.resources[0][:status]).must_equal 'HTTP/1.1 403 Forbidden'
    end

    it "leaves propstats empty" do
      _(response_level_response.resources[0][:propstats]).must_equal []
    end
  end

  describe "with multiple namespaces" do
    let(:multi_namespace_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
          <d:response>
            <d:href>/calendar/event.ics</d:href>
            <d:propstat>
              <d:prop>
                <d:getetag>"abc123"</d:getetag>
                <c:calendar-data>BEGIN:VCALENDAR</c:calendar-data>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    let(:multi_namespace_response){WebDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: multi_namespace_xml))}

    it "groups DAV properties under the DAV: namespace" do
      _(multi_namespace_response.resources[0][:propstats][0][:properties]['DAV:']['getetag']).must_equal '"abc123"'
    end

    it "groups CalDAV properties under the CalDAV namespace" do
      _(multi_namespace_response.resources[0][:propstats][0][:properties]['urn:ietf:params:xml:ns:caldav']['calendar-data']).must_equal 'BEGIN:VCALENDAR'
    end
  end

  describe "with the same local name in different namespaces" do
    let(:collision_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:x="http://example.com/custom">
          <d:response>
            <d:href>/file.txt</d:href>
            <d:propstat>
              <d:prop>
                <d:displayname>From DAV</d:displayname>
                <x:displayname>From custom</x:displayname>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    let(:collision_response){WebDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: collision_xml))}

    it "keeps both without collision" do
      properties = collision_response.resources[0][:propstats][0][:properties]
      _(properties['DAV:']['displayname']).must_equal 'From DAV'
      _(properties['http://example.com/custom']['displayname']).must_equal 'From custom'
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
