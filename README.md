# webdav

A Ruby WebDAV client library.

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

### REPORT

```ruby
response = dav.report('/calendars/user/', body: report_xml, depth: '1')
response.resources.each do |resource|
  puts resource[:href]
end
```

## Verbs

### WebDAV (RFC 4918 / RFC 3253)

- `propfind(path, body:, depth:)` — Retrieve properties
- `proppatch(path, body:)` — Modify properties
- `report(path, body:, depth:)` — Run a report query
- `mkcol(path)` — Create a collection
- `copy(path, to:, depth:, overwrite:)` — Copy a resource
- `move(path, to:, overwrite:)` — Move a resource
- `lock(path, body:)` — Lock a resource
- `unlock(path, token:)` — Unlock a resource

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

- `resources`
— an array of hashes, each with:
  - `href`
  - `properties`
  - `status`

## Errors

Responses with status >= 400 raise `WebDAV::Error`, which has `code`, `message`, and `body`.

## Dependencies

- [http.rb](https://github.com/thoran/http.rb)

## Licence

MIT
