# WebDAV/Error.rb
# WebDAV::Error.rb

class WebDAV
  class Error < StandardError
    attr_reader :code, :message, :body

    private

    def initialize(response)
      @code = response.code.to_i
      @message = response.message
      @body = response.body
      super("HTTP #{@code}: #{@message}")
    end
  end
end
