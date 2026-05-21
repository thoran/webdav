# WebDAV/Response.rb
# WebDAV::Response.rb

class WebDAV
  class Response
    attr_reader :code, :message, :headers, :body

    def success?
      code >= 200 && code < 300
    end

    def etag
      headers['ETag']
    end

    def content_type
      headers['Content-Type']
    end

    private

    def initialize(response)
      @code = response.code.to_i
      @message = response.message
      @headers = response
      @body = response.body
    end
  end
end
