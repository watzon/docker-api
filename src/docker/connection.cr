require "uri"
require "http/client"

module Docker
  class Connection
    include Docker::Exception

    @url : URI
    @ssl_context : OpenSSL::SSL::Context?
    @timeout : Int32? = nil

    delegate :get, :post, :put, :patch, :head, :delete, to: client

    getter url        : URI
    setter verify_tls : Bool?
    setter cert_path  : String?

    property timeout  : Int32?

    def initialize(
      @raw_url : String = ENV.fetch("DOCKER_URL", ENV.fetch("DOCKER_HOST", DEFAULT_URL)),
      @options : JSON::Any? = nil)
      @url = URI.parse(@raw_url)
    end

    def url=(raw_url)
      @url = URI.parse(raw_url)
    end

    def client
      client = nil

      if unix?
        client = HTTP::Client.unix(@url.to_s.sub(/^unix:\/\//, ""))
      elsif verify_tls?
        client = HTTP::Client.new(@url.host.not_nil!, @url.port.not_nil!, true)
        client.ssl_context = ssl_context
      else
        client = HTTP::Client.new(@url.host.not_nil!, @url.port.not_nil!, false)
      end

      client.connect_timeout= @timeout.as(Number) unless @timeout.nil?

      client.before_request do |request|
        request.headers["Content-Type"] = request.body ? "application/json" : "text/plain"
      end

      client
    end

    private def ssl_context
      @ssl_context ||= begin
        ctx = OpenSSL::SSL::Context::Client.new(LibSSL.tlsv1_method)
        ctx.private_key = key_file_path
        ctx.ca_file = ca_file_path
        ctx.certificate_file = cert_file_path
        ctx
      end
    end

    private def verify_tls?
      @verify_tls ||= tcp? && ENV.fetch("DOCKER_TLS_VERIFY", "0").to_i == 1
    end

    private def unix?
      @uri.scheme == "unix"
    end

    private def tcp?
      @url.scheme == "tcp" || @url.scheme == "http" || @url.scheme == "https"
    end

    private def unix?
      @url.scheme == "unix"
    end

    private def tcp?
      @url.scheme == "tcp" || @url.scheme == "http" || @url.scheme == "https"
    end

    private def cert_path
      @cert_path ||= ENV.fetch("DOCKER_CERT_PATH", DEFAULT_CERT_PATH)
    end

    private def ca_file_path
      "#{cert_path}/ca.pem"
    end

    private def key_file_path
      "#{cert_path}/key.pem"
    end

    private def cert_file_path
      "#{cert_path}/cert.pem"
    end
  end
end
