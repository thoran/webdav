# test/WebDAV/Response_test.rb

require_relative '../helper'

describe WebDAV::Response do
  let(:mock_response) do
    headers = {'ETag' => '"abc123"', 'Content-Type' => 'text/html'}
    response = MockResponse.new(
      code: '200',
      message: 'OK',
      body: '<html>Hello</html>',
      headers_hash: headers
    )
    response
  end

  let(:response){WebDAV::Response.new(mock_response)}

  describe "#code" do
    it "returns the status code as an integer" do
      _(response.code).must_equal 200
    end
  end

  describe "#message" do
    it "returns the status message" do
      _(response.message).must_equal 'OK'
    end
  end

  describe "#body" do
    it "returns the response body" do
      _(response.body).must_equal '<html>Hello</html>'
    end
  end

  describe "#success?" do
    it "returns true for 2xx responses" do
      _(response.success?).must_equal true
    end

    it "returns false for 3xx responses" do
      redirect_response = MockResponse.new(code: '302', message: 'Found', body: '')
      r = WebDAV::Response.new(redirect_response)
      _(r.success?).must_equal false
    end

    it "returns false for 4xx responses" do
      error_response = MockResponse.new(code: '404', message: 'Not Found', body: '')
      r = WebDAV::Response.new(error_response)
      _(r.success?).must_equal false
    end

    it "returns false for 5xx responses" do
      error_response = MockResponse.new(code: '500', message: 'Internal Server Error', body: '')
      r = WebDAV::Response.new(error_response)
      _(r.success?).must_equal false
    end
  end

  describe "#etag" do
    it "returns the ETag header" do
      _(response.etag).must_equal '"abc123"'
    end
  end

  describe "#content_type" do
    it "returns the Content-Type header" do
      _(response.content_type).must_equal 'text/html'
    end
  end
end
