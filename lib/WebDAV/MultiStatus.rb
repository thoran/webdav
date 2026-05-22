# WebDAV/MultiStatus.rb
# WebDAV::MultiStatus

require 'rexml/document'

require_relative './Response'

class WebDAV
  class MultiStatus < Response
    attr_reader :resources

    private

    def initialize(response)
      super
      @resources = parse
    end

    def parse
      doc = REXML::Document.new(body)
      doc.elements.collect('//d:response'){|response_element| parse_response(response_element)}
    end

    def parse_response(response_element)
      {
        href: response_element.elements['d:href']&.text,
        propstats: parse_propstats(response_element),
        status: parse_response_status(response_element)
      }
    end

    def parse_propstats(response_element)
      response_element.elements.collect('d:propstat'){|propstat_element| parse_propstat(propstat_element)}
    end

    def parse_propstat(propstat_element)
      {
        properties: parse_properties(propstat_element.elements['d:prop']),
        status: propstat_element.elements['d:status']&.text
      }
    end

    def parse_properties(prop_element)
      return {} unless prop_element
      prop_element.elements.to_a.each_with_object({}) do |property_element, result|
        result[property_element.namespace] ||= {}
        result[property_element.namespace][property_element.name] = property_element.text || property_element.to_s
      end
    end

    def parse_response_status(response_element)
      return nil if response_element.elements['d:propstat']
      response_element.elements['d:status']&.text
    end
  end
end
