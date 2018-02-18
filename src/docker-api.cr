require "logger"
require "json"
require "openssl"
require "http"

require "./core_ext/**"
require "./docker/version"
require "./docker/info"
require "./docker/util"
require "./docker/exception"
require "./docker/connection"
require "./docker/container"
require "./docker/event"
require "./docker/exec"
require "./docker/image"

# TODO: Write documentation for `Docker::Api`
module Docker

  VERSION = "0.1.0"
  API_VERSION = "1.24"

  Logger = ::Logger.new(STDOUT)
  Logger.level = ::Logger::INFO

  DEFAULT_URL = "unix:///var/run/docker.sock"
  DEFAULT_CERT_PATH = "#{ENV["HOME"]}/.docker"

  @@connection : Docker::Connection?
  @@url : String?
  @@options : (Hash(String, Bool | String) | Hash(String, String))?

  property creds : String

  def self.default_socket_url
    "unix:///var/run/docker.sock"
  end

  def self.env_url
    ENV["DOCKER_URL"]? || ENV["DOCKER_HOST"]?
  end

  def self.env_options
    if cert_path = ENV["DOCKER_CERT_PATH"]
      {
        "client_cert" => File.join(cert_path, "cert.pem"),
        "client_key" => File.join(cert_path, "key.pem"),
        "ssl_ca_file" => File.join(cert_path, "ca.pem"),
        "scheme" => "https",
        "ssl_verify_peer" => true
      }.merge(ssl_options)
    else
      {} of String => String
    end
  end

  def self.ssl_options
    if ENV["DOCKER_SSL_VERIFY"] == "false"
      {
        "ssl_verify_peer" => false
      }
    else
      {} of String => Bool
    end
  end

  def self.url
    @@url ||= env_url || default_socket_url
    # docker uses a default notation tcp:// which means tcp://localhost:2375
    if @@url == "tcp://"
      @@url = "tcp://localhost:2375"
    end
    @@url.not_nil!
  end

  def self.options
    @@options ||= env_options
  end

  def self.url=(new_url)
    @@url = new_url
    reset_connection!
  end

  def self.options=(new_options)
    @@options = env_options.merge(new_options || {} of String => String)
    reset_connection!
  end

  def self.connection
    @@connection ||= Connection.new(url, nil)
  end

  def self.reset!
    @@url = nil
    @@options = nil
    reset_connection!
  end

  def self.reset_connection!
    @@connection = nil
  end

  # Get the version of Go, Docker, and optionally the Git commit.
  def self.version(connection = self.connection)
    response = connection.get("/version")
    Docker::Version.from_json(response.body)
  end

  # Get more information about the Docker server.
  def self.info(connection = self.connection)
    response = connection.get("/info")
    Docker::Info.from_json(response.body)
  end

  # Ping the Docker server.
  def self.ping(connection = self.connection)
    connection.get("/_ping")
  end

  def self.authenticate!(options = {} of String => String, connection = self.connection)
    creds = options.to_json
    connection.post("/auth", body: creds)
    @@creds = creds
    true
  end
end

p Docker::Util.build_auth_header({
  "serveraddress" => "test.com",
  "username" => "watzon",
  "password" => "password",
  "email" => "chris@watzon.me"
})
