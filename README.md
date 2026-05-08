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
  puts resource[:properties]
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

`WebDAV::MultiStatus` additionally provides:

- `resources` — an array of hashes, each with:
  - `href`
  - `properties`
  - `status`


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
