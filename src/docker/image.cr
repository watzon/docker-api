module Docker
  class Image

    PARAMS = {
      id: { key: "Id", type: String, nilable: true },
      container: { key: "Container", type: String, nilable: true },
      comment: { key: "Comment", type: String, nilable: true },
      os: { key: "Os", type: String, nilable: true },
      architecture: { key: "Architecture", type: String, nilable: true },
      parent: { key: "Parent", type: String, nilable: true },
      container_config: { key: "ContainerConfig", type: Container::Config, nilable: true },
      docker_version: { key: "DockerVersion", type: String, nilable: true },
      virtual_size: { key: "VirtualSize", type: Int32, nilable: true },
      size: { key: "Size", type: Int32, nilable: true },
      author: { key: "Author", type: String, nilable: true },
      created: { key: "Created", type: String, nilable: true },
      graph_driver: { key: "GraphDriver", type: GraphDriver, nilable: true },
      repo_digests: { key: "RepoDigests", type: Array(String), nilable: true },
      repo_tags: { key: "RepoTags", type: Array(String), nilable: true },
      config: { key: "Config", type: Config, nilable: true },
      root_fs: { key: "RootFS", type: RootFs, nilable: true }
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

    class GraphDriver

      JSON.mapping({
        name: { key: "Name", type: String, nilable: true },
        data: { key: "Data", type: JSON::Any, nilable: true }
      })

    end

    class Config

      JSON.mapping({
        image: { key: "Image", type: String, nilable: true },
        network_disabled: { key: "NetworkDisabled", type: Bool, nilable: true },
        on_build: { key: "OnBuild", type: Array(JSON::Any), nilable: true },
        stdin_once: { key: "StdinOnce", type: Bool, nilable: true },
        publish_service: { key: "PublishService", type: String, nilable: true },
        attach_stdin: { key: "AttachStdin", type: Bool, nilable: true },
        open_stdin: { key: "OpenStdin", type: Bool, nilable: true },
        domainname: { key: "Domainname", type: String, nilable: true },
        attach_stdout: { key: "AttachStdout", type: Bool, nilable: true },
        tty: { key: "Tty", type: Bool, nilable: true },
        hostname: { key: "Hostname", type: String, nilable: true },
        volumes: { key: "Volumes", type: JSON::Any, nilable: true },
        cmd: { key: "Cmd", type: Array(String), nilable: true },
        exposed_ports: { key: "ExposedPorts", type: JSON::Any, nilable: true },
        env: { key: "Env", type: Array(String), nilable: true },
        labels: { key: "Labels", type: Hash(String, String), nilable: true },
        entrypoint: { key: "Entrypoint", type: JSON::Any, nilable: true },
        mac_address: { key: "MacAddress", type: String, nilable: true },
        attach_stderr: { key: "AttachStderr", type: Bool, nilable: true },
        working_dir: { key: "WorkingDir", type: String, nilable: true },
        user: { key: "User", type: String, nilable: true }
      })

    end

    class RootFs

      JSON.mapping({
        type: { key: "Type", type: String, nilable: true },
        layers: { key: "Layers", type: Array(String), nilable: true }
      })

    end
  end
end
