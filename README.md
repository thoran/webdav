# webdav

A WebDAV client library for Ruby.


## Installation

```
gem install webdav
```

Or in your Gemfile:

```ruby
gem 'webdav'
```


## Usage

```ruby
require 'webdav'

dav = WebDAV.new('https://dav.example.com/files/', username: 'user', password: 'pass')
```

### Discovering resources

```ruby
response = dav.propfind('/', depth: '1')
response.resources.each do |resource|
  puts resource[:href]
  resource[:propstats].each do |propstat|
    puts propstat[:status]
    propstat[:properties].each do |namespace, properties|
      properties.each do |name, value|
        puts "  #{namespace} #{name} = #{value}"
      end
    end
  end
end
```

### Reading a resource

```ruby
response = dav.get('/documents/report.txt')
puts response.body
```

### Writing a resource

```ruby
dav.put('/documents/report.txt', body: 'Hello, world.', content_type: 'text/plain')
```

### Deleting a resource

```ruby
dav.delete('/documents/report.txt')
```

### Creating a collection

```ruby
dav.mkcol('/documents/archive/')
```

### Copying and moving

```ruby
dav.copy('/documents/report.txt', to: '/archive/report.txt')
dav.move('/documents/draft.txt', to: '/documents/final.txt')
```

### Locking and unlocking

```ruby
lock_body = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <d:lockinfo xmlns:d="DAV:">
    <d:lockscope><d:exclusive/></d:lockscope>
    <d:locktype><d:write/></d:locktype>
  </d:lockinfo>
XML

response = dav.lock('/documents/report.txt', body: lock_body)
# ...
dav.unlock('/documents/report.txt', token: 'urn:uuid:...')
```

### Reporting

```ruby
response = dav.report('/calendars/user/', body: report_xml, depth: '1')
response.resources.each do |resource|
  puts resource[:href]
end
```


## Concepts

WebDAV extends HTTP with a few ideas that don't have direct REST analogues. The ones below explain why the API is shaped the way it is.

### Properties vs content

A WebDAV resource has two faces. **Content** is what GET returns — the bytes of the file. **Properties** are metadata associated with the resource: display name, creation date, lock state, content type, and any custom properties the server defines. The same URL identifies both, but different verbs reach them — GET/PUT for content, PROPFIND/PROPPATCH for properties.

### Collections and the trailing slash

A **collection** is WebDAV's directory: a resource that contains other resources. MKCOL creates one. By convention, collection URLs end in `/` and ordinary resources don't; servers that care about the distinction will redirect or 404 if you get it wrong. The distinction matters because COPY, MOVE, and DELETE on a collection cascade to its children — which is also why those verbs can return 207 Multi-Status when children succeed and fail independently.

### Why 207 Multi-Status exists

HTTP assumes one request maps to one status. WebDAV breaks that assumption: PROPFIND on a folder asks about many resources at once; COPY of a tree may succeed on some children and fail on others. The 207 Multi-Status response code says "the request touched many things; here are per-thing outcomes." The XML body carries one `<d:response>` per affected resource. This gem returns those as `WebDAV::MultiStatus`; the `resources` accessor exposes the per-resource detail (see [Responses](#responses)).

### Namespaces

WebDAV properties are XML elements, and XML elements belong to namespaces. The core RFC 4918 properties live in the `DAV:` namespace. Extensions — CalDAV (`urn:ietf:params:xml:ns:caldav`), CardDAV, Exchange, ownCloud, custom server vocabularies — each define their own. Properties from different namespaces can share local names (`<d:displayname>` and `<x:displayname>` are different properties), so the parser preserves namespace URIs as the outer key in the properties hash.


## Methods

WebDAV extends HTTP with additional methods for distributed authoring. This gem provides all the methods defined in RFC 4918 ("HTTP Extensions for Web Distributed Authoring and Versioning") and the REPORT method from RFC 3253 ("Versioning Extensions to WebDAV"), which is essential for CalDAV and CardDAV queries.

Ruby's standard library includes request classes for the RFC 4918 methods (Propfind, Proppatch, Mkcol, Copy, Move, Lock, Unlock) but not for REPORT. This gem defines `Net::HTTP::Report` to fill that gap.

These methods are not provided by the `http.rb` gem, which deliberately limits itself to the core HTTP methods defined in RFC 9110 ("HTTP Semantics") and RFC 5789 ("PATCH Method for HTTP").

### Properties (RFC 4918)

- `propfind(path, body:, depth:)` — retrieve properties from a resource
- `proppatch(path, body:)` — set or remove properties on a resource

### Versioning (RFC 3253)

- `report(path, body:, depth:)` — query for information about a resource; used by CalDAV and CardDAV

### Collections (RFC 4918)

- `mkcol(path)` — create a new collection (directory)

### Namespace (RFC 4918)

- `copy(path, to:, depth:, overwrite:)` — copy a resource
- `move(path, to:, overwrite:)` — move a resource

### Locking (RFC 4918)

- `lock(path, body:)` — lock a resource
- `unlock(path, token:)` — unlock a resource

### Standard HTTP

- `get(path)`
- `head(path)`
- `post(path, body:, content_type:)`
- `put(path, body:, content_type:)`
- `patch(path, body:, content_type:)`
- `delete(path)`
- `options(path)`
- `trace(path)`


## Responses

All methods return either a `WebDAV::Response` or a `WebDAV::MultiStatus`.

`WebDAV::Response` provides

- `code`
- `message`
- `headers`
- `body`
- `etag`
- `content_type`
- `success?`

A `GET` response on the wire:

```
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 13
ETag: "5d41402a"

Hello, world.
```

Parses to:

```ruby
response.code          # => 200
response.message       # => "OK"
response.body          # => "Hello, world."
response.etag          # => "\"5d41402a\""
response.content_type  # => "text/plain"
response.success?      # => true
```

`WebDAV::MultiStatus` additionally provides:

- `resources` — an array of hashes, each with:
  - `href` — the resource URL
  - `propstats` — an array of `{properties:, status:}` hashes (PROPFIND / PROPPATCH / REPORT). May be empty when the response carries a response-level status instead.
  - `status` — the response-level status string (COPY / MOVE / DELETE). `nil` when the response has propstats instead.

Within a propstat, `properties` is a nested hash keyed first by XML namespace URI, then by local name. For example, a CalDAV calendar property appears as `propstat[:properties]['urn:ietf:params:xml:ns:caldav']['calendar-data']` and a DAV property as `propstat[:properties]['DAV:']['getetag']`. Keeping the namespace explicit prevents collisions between properties from different namespaces that share a local name.

A PROPFIND response — properties grouped by namespace, status per propstat, response-level status `nil`. The wire XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:response>
    <d:href>/calendar/event.ics</d:href>
    <d:propstat>
      <d:prop>
        <d:getetag>"abc123"</d:getetag>
        <c:calendar-data>BEGIN:VCALENDAR...</c:calendar-data>
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
```

Parses to:

```ruby
[
  {
    href: '/calendar/event.ics',
    propstats: [
      {
        properties: {
          'DAV:' => {'getetag' => '"abc123"'},
          'urn:ietf:params:xml:ns:caldav' => {'calendar-data' => 'BEGIN:VCALENDAR...'}
        },
        status: 'HTTP/1.1 200 OK'
      },
      {
        properties: {'DAV:' => {'getctag' => ''}},
        status: 'HTTP/1.1 404 Not Found'
      }
    ],
    status: nil
  }
]
```

A COPY / MOVE / DELETE on a collection where a child resource failed — the server returns 207 Multi-Status with one `<d:response>` per affected child, each carrying a response-level status rather than propstats. Single-resource lifecycle operations don't go through this path; they return a plain `WebDAV::Response` with the status code as the whole story. The wire XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dir/file.txt</d:href>
    <d:status>HTTP/1.1 403 Forbidden</d:status>
  </d:response>
</d:multistatus>
```

Parses to:

```ruby
[
  {
    href: '/dir/file.txt',
    propstats: [],
    status: 'HTTP/1.1 403 Forbidden'
  }
]
```


## Errors

Responses with status >= 400 raise `WebDAV::Error`, which has `code`, `message`, and `body`.


## Dependencies

- [http.rb](https://github.com/thoran/http.rb)


## Contributing

1. Fork it [https://github.com/thoran/webdav/fork](https://github.com/thoran/webdav/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new pull request


## Licence

MIT
