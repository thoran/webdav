# test/Net/HTTP/Report_test.rb

require_relative '../../helper'

describe Net::HTTP::Report do
  it "is a subclass of Net::HTTPRequest" do
    _(Net::HTTP::Report < Net::HTTPRequest).must_equal(true)
  end

  it "has the correct METHOD" do
    _(Net::HTTP::Report::METHOD).must_equal('REPORT')
  end

  it "accepts a body" do
    _(Net::HTTP::Report::REQUEST_HAS_BODY).must_equal(true)
  end

  it "expects a response body" do
    _(Net::HTTP::Report::RESPONSE_HAS_BODY).must_equal(true)
  end
end
