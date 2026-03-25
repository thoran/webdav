# test/WebDAV/Error_test.rb

require_relative '../helper'

describe WebDAV::Error do
  let(:mock_response) do
    MockResponse.new(
      code: '404',
      message: 'Not Found',
      body: '<!DOCTYPE html><html><body>Not Found</body></html>'
    )
  end

  let(:error){WebDAV::Error.new(mock_response)}

  describe "#code" do
    it "returns the status code as an integer" do
      _(error.code).must_equal 404
    end
  end

  describe "#message" do
    it "returns the status message" do
      _(error.message).must_equal 'Not Found'
    end
  end

  describe "#body" do
    it "returns the response body" do
      _(error.body).must_include 'Not Found'
    end
  end

  describe "#to_s" do
    it "includes the status code and message" do
      _(error.to_s).must_equal 'HTTP 404: Not Found'
    end
  end

  describe "inheritance" do
    it "is a StandardError" do
      _(error).must_be_kind_of StandardError
    end

    it "can be raised and rescued" do
      assert_raises(WebDAV::Error) do
        raise WebDAV::Error.new(mock_response)
      end
    end
  end

  describe "with a 401 status code" do
    let(:mock_response) do
      MockResponse.new(
        code: '401',
        message: 'Unauthorized',
        body: ''
      )
    end

    let(:error){WebDAV::Error.new(mock_response)}

    it "handles a 401 error" do
      _(error.code).must_equal 401
      _(error.to_s).must_equal 'HTTP 401: Unauthorized'
    end
  end

  describe "with a 500 status code" do
    let(:mock_response) do
      MockResponse.new(
        code: '500',
        message: 'Internal Server Error',
        body: ''
      )
    end

    let(:error){WebDAV::Error.new(mock_response)}

    it "handles a 500 error" do
      _(error.code).must_equal 500
      _(error.to_s).must_equal 'HTTP 500: Internal Server Error'
    end
  end
end
