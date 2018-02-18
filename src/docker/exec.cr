module Docker
  class Exec

    @connection : Docker::Connection = Docker.connection

    private def initialize(@id : String, @connection : Docker::Connection = Docker.connection)

    end

    def self.create(options = {} of String => String, conn = Docker.connection)
      container = options.delete("Container")
      response = conn.post("/containers/#{container}/exec", body: options.to_json)
      json = JSON.parse(response.body)
      new(json["Id"].as_s, conn)
    end

    def json
      response = connection.get(path_for(:json))
      Docker::Exec::Info.from_json(response.body)
    end

    def start!(options = {} of String => String)

      tty = !!options.delete("tty")
      detached = !!options.delete("detach")
      stdin = options["stdin"].as_bool
      read_timeout = options["wait"].as_bool

      body = {
        Tty: tty,
        Detach: detached
      }

      # msgs = Docker::Messages.new
      # unless detached
      #   if stdin

      #   else

      #   end
      # end

      connection.timeout = read_timeout unless read_timeout.nil?

      connection.post(path_for(:start), body: body.to_json)
    end

    def start(options = {} of String => String)
      begin
        start!(options)
      rescue ex
        nil
      end
    end

    def resize(query = {} of String => String)
      query = "?" + HTTP::Params.encode(query) unless query.empty?
      connection.post(path_for(:resize) + query.to_s)
      self
    end

    private def path_for(endpoint)
      "/exec/#{@id}/#{endpoint}"
    end

    class Info
      PROPERTIES = {
        can_remove: { key: "CanRemove", nilable: true, type: Bool },
        container_id: { key: "ContainerID", nilable: true, type: String },
        detach_keys: { key: "DetachKeys", nilable: true, type: String },
        exit_code: { key: "ExitCode", nilable: true, type: Int32 },
        id: { key: "ID", nilable: true, type: String },
        open_stderr: { key: "OpenStderr", nilable: true, type: Bool },
        open_stdin: { key: "OpenStdin", nilable: true, type: Bool },
        open_stdout: { key: "OpenStdout", nilable: true, type: Bool },
        process_config: { key: "ProcessConfig", nilable: true, type: NamedTuple(
          arguments: Array(String),
          entrypoint: String,
          privileged: String,
          tty: Bool,
          user: String
        ) },
        running: { key: "Running", nilable: true, type: Bool }
      }

      JSON.mapping({{PROPERTIES}})
    end
  end
end
