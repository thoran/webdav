# WebDAV.rb
# WebDAV

gem 'http.rb'; require 'http.rb'
require 'net/http'
require 'rexml/document'
require 'uri'

require_relative './String/to_const'
require_relative './WebDAV/Error'
require_relative './WebDAV/MultiStatus'
require_relative './WebDAV/Response'

class WebDAV

  # Properties

  def propfind(path = '/', body: nil, depth: '1')
    response = request(:propfind, path, body: body, headers: {'Depth' => depth})
    handle_response(response)
  end

  def proppatch(path, body:)
    response = request(:proppatch, path, body: body)
    handle_response(response)
  end

  # Reports

  def report(path, body:, depth: '1')
    response = request(:report, path, body: body, headers: {'Depth' => depth})
    handle_response(response)
  end

  # Collections

  def mkcol(path)
    response = request(:mkcol, path)
    handle_response(response)
  end

  # Namespace

  def copy(path, to:, depth: 'infinity', overwrite: true)
    response = request(:copy, path, headers: {
      'Destination' => resolve_uri(to).to_s,
      'Depth' => depth,
      'Overwrite' => overwrite ? 'T' : 'F'
    })
    handle_response(response)
  end

  def move(path, to:, overwrite: true)
    response = request(:move, path, headers: {
      'Destination' => resolve_uri(to).to_s,
      'Overwrite' => overwrite ? 'T' : 'F'
    })
    handle_response(response)
  end

  # Locking

  def lock(path, body:)
    response = request(:lock, path, body: body)
    handle_response(response)
  end

  def unlock(path, token:)
    response = request(:unlock, path, headers: {'Lock-Token' => "<#{token}>"})
    handle_response(response)
  end

  # Standard HTTP

  def get(path)
    response = request(:get, path)
    handle_response(response)
  end

  def head(path)
    response = request(:head, path)
    handle_response(response)
  end

  def post(path, body:, content_type: 'application/xml')
    response = request(:post, path, body: body, headers: {'Content-Type' => content_type})
    handle_response(response)
  end

  def put(path, body:, content_type: 'application/octet-stream')
    response = request(:put, path, body: body, headers: {'Content-Type' => content_type})
    handle_response(response)
  end

  def patch(path, body:, content_type: 'application/xml')
    response = request(:patch, path, body: body, headers: {'Content-Type' => content_type})
    handle_response(response)
  end

  def delete(path)
    response = request(:delete, path)
    handle_response(response)
  end

  def options(path = '/')
    response = request(:options, path)
    handle_response(response)
  end

  def trace(path)
    response = request(:trace, path)
    handle_response(response)
  end

  private

  def initialize(uri, username:, password:)
    @uri = uri.is_a?(URI) ? uri : URI.parse(uri)
    @username = username
    @password = password
  end

  def resolve_uri(path)
    URI.join(@uri, path)
  end

  def request_uri(path)
    resolve_uri(path).request_uri
  end

  def default_headers
    {'Content-Type' => 'application/xml; charset=utf-8'}
  end

  def request_class(verb)
    "Net::HTTP::#{verb.to_s.capitalize}".to_const
  end

  def request(verb, path, body: nil, headers: {})
    request_object = request_class(verb).new(request_uri(path))
    request_object.basic_auth(@username, @password)
    request_object.body = body if body
    merged_headers = default_headers.merge(headers)
    merged_headers.each{|k, v| request_object[k] = v}
    HTTP.request(resolve_uri(path), request_object)
  end

  def handle_response(response)
    raise WebDAV::Error.new(response) if response.code.to_i >= 400
    case response.code.to_i
    when 207
      MultiStatus.new(response)
    else
      Response.new(response)
    end
  end
end
