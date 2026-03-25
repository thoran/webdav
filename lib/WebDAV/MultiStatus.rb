# WebDAV/MultiStatus.rb
# WebDAV::MultiStatus

require_relative './Response'

class WebDAV
  class MultiStatus < Response
    attr_reader :resources

    def parse
      doc = REXML::Document.new(body)
      resources = []
      doc.elements.each('//d:response') do |resp|
        href = resp.elements['.//d:href']&.text
        properties = {}
        resp.elements.each('.//d:prop/*') do |prop|
          properties[prop.name] = prop.text || prop.to_s
        end
        status = resp.elements['.//d:status']&.text
        resources << {href: href, properties: properties, status: status}
      end
      resources
    end

    private

    def initialize(response)
      super
      @resources = parse
    end
  end
end
