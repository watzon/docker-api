module Docker
  class Image

    PARAMS = {
      id: { key: "Id", type: String },
      container: { key: "Container", nilable: true, type: String },
      comment: { key: "Comment", nilable: true, type: String },
      os: { key: "Os", nilable: true, type: String },
      architecture: { key: "Architecture", nilable: true, type: String },
      parent: { key: "Parent", nilable: true, type: String },
      container_config: { key: "ContainerConfig", nilable: true, type: Container::Config },
      docker_version: { key: "DockerVersion", nilable: true, type: String },
      virtual_size: { key: "VirtualSize", nilable: true, type: Int32 },
      size: { key: "Size", nilable: true, type: Int32 },
      author: { key: "Author", nilable: true, type: Int32 }
    }

    @connection : Docker::Connection = Docker.connection

    private def initialize(@id : String, @connection : Docker::Connection = Docker.connection)
    end

    def run(cmd, options)
      opts = { "image" => @id }.merge(options)
      opts["command"] = cmd.is_a?(String) ? cmd.split(/\s+/) : cmd
      begin
        Docker::Container.create(**opts, connection: connection)
          .tap(&.start!)
      rescue exception

      end
    end

    def self.create(opts = {} of String => String, creds = nil, conn = Docker.connection)
      credentials = creds.nil? ? Docker.creds : creds.to_json
      headers = credentials && Docker::Util.build_auth_header(credentials) || {} of String => String
      headers = HTTP::Headers { headers }
      query = "?" + HTTP::Params.encode(opts) unless opts.empty?
      response = conn.post("/images/create" + query.to_s, headers: headers)
      image = opts["fromImage"]?
      tag = opts["tag"]?
      image = "#{image}:#{tag}" if tag && !image.end_with?(":#{tag}")
      get(image, {} of String => String, conn)
    end

    def self.get(id, opts = {} of String => String, conn = Docker.connection)
      query = "?" + HTTP::Params.encode(opts) unless opts.nil?
      response = conn.get("/images/#{URI.encode(id)}/json" + query.to_s)

    end
  end
end
