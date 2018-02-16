require "json"

module Docker::Base
  include Docker::Exception

  @connection : Docker::Connection
  @info : Hash(String, JSON::Type)
  @id : String

  property :connection, :info
  getter :id

  private def initialize(connection : Docker::Connection, hash = {} of String => JSON::Any)
    normalize_hash(hash)
    raise ArgumentException.new("Must have id, got: #{hash}") unless hash["id"]?
    @connection, @info, @id = connection, hash.as_h, hash["id"].as_s
  end

  def normalize_hash(hash)
    hash = hash.as_h
    hash["id"] ||= hash.delete("ID") || hash.delete("Id")
  end
end
