# docker-api

Complete docker api wrapper for Crystal. Based off of the [docker-api](https://github.com/swipely/docker-api) Ruby Gem.

_This is very much alpha software and should be treated as such._

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  docker-api:
    github: watzon/docker-api
```

## Usage

```crystal
require "docker-api"

# List versions
version = Docker.version
p version # => #<Docker::Types::Version:0x564e6108fcb0 ...

# Get all containers
containers = Docker::Container.all
first_one = containers.first

# Get info about the container
p first_one.info # => { "Names" => [...], "Image" => "...", ... }

# Remove the container
first_one.remove

# Spin up a new container
container = Docker::Container.create("some-redis", { image: "redis" })
p container.info # => { "Names" => ["some-redis"], "Image" => "redis", ... }
```

## Development

### Current features

- [x] API Connector
- [x] Containers
- [ ] Events
- [ ] Exec
- [ ] Image
- [ ] Messages
- [ ] Network
- [ ] Volume

### Hangups

- The docker `/archive` method requires tar packing/unpacking.

## Contributing

1. Fork it ( https://github.com/watzon/docker-api/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon) Chris Watson - creator, maintainer
