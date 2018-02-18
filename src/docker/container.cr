module Docker
  class Container
    include Docker::Exception

    macro make_initializer(properties)
      {% for key, value in properties %}
        {% properties[key] = {type: value} unless value.is_a?(NamedTupleLiteral) %}
      {% end %}


      {% for key, value in properties %}
        {% if value[:mustbe] || value[:mustbe] == false %}
          @{{key.id}} : {{value[:type]}}
        {% end %}
      {% end %}
      def initialize(
        conn : Docker::Connection,
        {% for key, value in properties %}
          {% if !value[:nilable] && !value[:mustbe] && value[:mustbe] != false %}
            @{{key.id}} : {{ (value[:nilable] ? "#{value[:type]}? = nil, " : "#{value[:type]},").id }}
          {% end %}
        {% end %}
        {% for key, value in properties %}
          {% if value[:nilable] && !value[:mustbe] && value[:mustbe] != false %}
            @{{key.id}} : {{ (value[:nilable] ? "#{value[:type]}? = nil, " : "#{value[:type]},").id }}
          {% end %}
        {% end %}
        )
        @connection = conn
        {% for key, value in properties %}
          {% if value[:mustbe] || value[:mustbe] == false %}
            @{{key.id}} = {{value[:mustbe]}}
          {% end %}
        {% end %}
      end
    end

    @connection : Docker::Connection = Docker.connection
    @info : Hash(String, JSON::Type)? = nil

    property :connection, :info

    PROPERTIES = {
      id: { key: "Id", type: String},
      names: { key: "Names", nilable: true, type: Array(String) },
      image: { key: "Image", nilable: true, type: String },
      image_id: { key: "ImageID", nilable: true, type: String },
      command: { key: "Command", nilable: true, type: String },
      created: { key: "Created", nilable: true, type: Int64 },
      state: { key: "State", nilable: true, type: String  },
      status: { key: "Status", nilable: true, type: String },
      ports: { key: "Ports", nilable: true, type: Array(Port) },
      labels: { key: "Labels", nilable: true, type: Hash(String, String) },
      size_rw: { key: "SizeRw", nilable: true, type: Int32 },
      size_root_fs: { key: "SizeRootFs", nilable: true, type: Int32 },
      network_settings: { key: "NetworkSettings", nilable: true, type: Hash(String, JSON::Any) },
      mounts: { key: "Mounts", nilable: true, type: Array(Hash(String, JSON::Any)) }
    }

    JSON.mapping({{PROPERTIES}})

    make_initializer({{PROPERTIES}})

    # Update the info hash, which is the only mutable state in this object.
    #   e.g. if you would like a live status from the #info hash, call #refresh! first.
    def refresh!
      other = Docker::Container.all({ all: true }, connection).find do |c|
        c.id.starts_with?(self.id) || self.id.starts_with?(c.id)
      end

      info.merge!(self.json)
      other && info.merge!(other.info) { |key, info_value, other_value| info_value }
      self
    end

    def info
      @info ||= self.json
    end

    # Return a List of Hashes that represents the top running processes.
    def top(ps_args : String = "-ef")
      query = HTTP::Params.encode({ ps_args: ps_args })
      response = connection.get(path_for(:top) + "?" + ps_args)
      JSON.parse(response.body)
    end

    # Wait for the current command to finish executing.
    def wait(time = nil)
      conn = connection
      conn.connect_timeout = time unless time.nil?
      response = conn.post(path_for(:wait))
      JSON.parse(response)
    end

    # Given a command and an optional number of seconds to wait for the currently
    # executing command, creates a new Container to run the specified command. If
    # the command that is currently executing does not return a 0 status code, an
    # UnexpectedResponseError is raised.
    def run(cmd, time = 1000)
      if (code = tap(&.start).wait(time)["StatusCode"]?).zero?
        commit.run(cmd)
      else
        raise Exception::UnexpectedResponseException.new("Command returned status code #{code}.")
      end
    end

    # Create an Exec instance inside the container
    # def exec(command, options = {} of String => String, &block)
    #   # Establish values
    #   tty = options.delete(:tty) || false
    #   detach = options.delete(:detach) || false
    #   user = options.delete(:user)
    #   stdin = options.delete(:stdin)
    #   stdout = options.delete(:stdout) || !detach
    #   stderr = options.delete(:stderr) || !detach
    #   wait = options.delete(:wait)

    #   opts = {
    #     "Container" => self.id,
    #     "User" => user,
    #     "AttachStdin" => !!stdin,
    #     "AttachStdout" => stdout,
    #     "AttachStderr" => stderr,
    #     "Tty" => tty,
    #     "Cmd" => command
    #   }.merge(options)

    #   # Create Exec Instance
    #   instance = Docker::Exec.create(opts, self.connection)

    #   start_opts = {
    #     tty: tty,
    #     stdin: stdin,
    #     detach: detach,
    #     wait: wait
    #   }

    #   if detach
    #     instance.start!(start_opts)
    #     return instance
    #   else
    #     instance.start!(start_opts, &block)
    #   end
    # end

    def export
      connection.get(path_for(:export))
      self
    end

    def export(&block)
      connection.get(path_for(:export)) do |response|
        yield block
      end
      self
    end

    def attach(options = {} of String => String, &block)
      stdin = options.delete("stdin")
      tty = options.delete("tty")

      opts = {
        "stream" => "true", "stdout" => "true", "stderr" => "true"
      }.merge(options)

      # msgs = Docker::Messages.new

      if stdin
        # If attaching to stdin, we must hijack the underlying TCP connection
        # so we can stream stdin to the remote Docker process
        opts["stdin"] = "true"
      end

      query = "?" + HTTP::Params.encode(opts)

      connection.post(path_for(:attach) + query) do |response|
        yield response
      end

      self
    end

    # # Create an Image from a Container's changes
    # def commit(options = {} of String => String)
    #   options.merge!({"container" => @id[0...7]})
    #   config = { "run" => options.delete("run") }.to_json
    #   query = "?" + HTTP::Params.encode(options)
    #   response = connection.post("/commit" + query, body: config)
    #   hash = JSON.parse(response.body)
    #   Docker::Image.new(connection, hash)
    # end

    def to_s
      "Docker::Container { id: #{@id}, connection: #{connection} }"
    end

    def json
      response = connection.get(path_for(:json))
      JSON.parse(response.body).as_h
    end

    def changes
      response = connection.get(path_for(:changes))
      if response.body.chomp == "null"
        [] of NamedTuple(path: String, kind: Int32)
      else
        Array(NamedTuple(path: String, kind: Int32)).from_json(response.body)
      end
    end

    def logs(options)
      query = HTTP::Params.encode(options)
      response = connection.get(path_for(:logs) + "?" + query)
      response.body
    end

    def stats
      query = HTTP::Params.encode({ stream: "0" })
      response = connection.get(path_for(:stats) + "?" + query)
      JSON.parse(response.body).as_h
    end

    def stats(&block)
      connection.get(path_for(:stats)) do |response|
        yield response
      end
    end

    def rename(new_name)
      query = HTTP::Params.encode({ name: new_name })
      connection.post(path_for(:rename) + "?" + query)
    end

    def update(options)
      connection.post(path_for(:update), body: options.to_json)
    end

    def streaming_logs(options : Hash(String, _) = {} of String => String, &block)

    end

    {% for method in %w(start kill) %}
      def {{ method.id }}(opts = {} of String => String)
        connection.post(path_for({{ method }}), body: opts.to_json)
        self
      end

      def {{ method.id }}?(opts = {} of String => String)
        {{ method.id }}(opts)
      rescue ex
        nil
      end
    {% end %}

    {% for method in %w(stop restart) %}
      def {{ method.id }}(timeout = nil)
        conn = connection
        conn.connect_timeout = timeout.to_i + 5 unless timeout.nil?
        query =  timeout ? "?" + HTTP::Params.encode({ t: timeout.to_s }) : ""
        conn.post(path_for({{ method }}) + query)
        self
      end

      def {{ method.id }}?(timeout = nil)
        {{ method.id }}(timeout)
      rescue ex
        nil
      end
    {% end %}

    {% for method in %w(pause unpause) %}
      def {{ method.id }}
        conn.post(path_for({{ method }}))
        self
      end

      def {{ method.id }}?
        {{ method.id }}
      rescue ex
        nil
      end
    {% end %}

    def remove(options : Hash(String, _) = {} of String => String)
      connection.delete("/containers/#{@id}", body: options.to_json)
      nil
    end

    def copy(path)
      body = { Resource: path }
      connection.post(path_for(:copy), body: body.to_json)
      self
    end

    def archive_out(path, &block)
      query = "?" + HTTP::Params.encode({ path: path })
      connection.get(path_for(:archive) + query)
      self
    end

    # # TODO: Implement tar archive support first, then this
    # def archive_in(inputs, output_path, opts : (Hash(String, _) | NamedTuple) = {} of String => String)

    # end

    # def archive_in_stream(output_path, opts : (Hash(String, _) | NamedTuple) = {} of String => String, &block)
    #   overwrite = opts["overwrite"]? || false
    #   headers = HTTP::Headers { "Content-Type" => "application/x-tar" }

    #   connection.put(path_for(:archive), headers: headers) do |response|
    #     yield response
    #   end

    #   self
    # end

    # def read_file(path)

    # end

    # def store_file(path, file_content)

    # end

    # Create a new Container.
    def self.create(name = nil, opts = {} of String => String, conn = Docker.connection)
      query = "?" + HTTP::Params.encode({ name: name }) unless name.nil?
      config = Container::Config.new(**opts)
      response = conn.post("/containers/create" + query.to_s, body: config.to_json)
      Docker::Container.from_json(response.body)
    end

    # Get a Container by its id.
    def self.get(id, opts : (Hash(String, _) | NamedTuple) = {} of String => String, conn = Docker.connection)
      response = conn.get("/containers/#{id}/json", body: opts.to_json)
      json = JSON.parse(response.body)
      container = Docker::Container.new(json["Id"].as_s, conn)
      container.info
    end

    # Return all Containers.
    def self.all(opts : (Hash(String, _) | NamedTuple) = {} of String => String, conn = Docker.connection)
      response = conn.get("/containers/json", body: opts.to_json)
      Array(Docker::Container).from_json(response.body)
    end

    # Prune images.
    def self.prune(conn = Docker.connection)
      conn.post("/containers/prune")
      nil
    end

    # Convenience method to return the path for a particular resource.
    private def path_for(resource)
      "/containers/#{@id}/#{resource.to_s}"
    end

    struct Port
      JSON.mapping(
        private_port: { key: "PrivatePort", nilable: true, type: Int32 },
        public_port: { key: "PublicPort", nilable: true, type: Int32 },
        type: { key: "Type", nilable: true, type: String }
      )
    end

    struct NetworkSettings
      JSON.mapping(
        networks: { key: "Networks", nilable: true, type: Hash(String, JSON::Any) }
      )
    end

    class Config

      PROPERTIES = {
        hostname: { key: "Hostname", nilable: true, type: String },
        domainname: { key: "Domainname", nilable: true, type: String },
        user: { key: "User", nilable: true, type: String },
        attach_stdin: { key: "AttachStdin", nilable: true, type: Bool },
        attach_stdout: { key: "AttachStdout", nilable: true, type: Bool },
        attach_stderr: { key: "AttachStderr", nilable: true, type: Bool },
        tty: { key: "Tty", nilable: true, type: Bool },
        open_stdin: { key: "OpenStdin", nilable: true, type: Bool },
        stdin_once: { key: "StdinOnce", nilable: true, type: Bool },
        env: { key: "Env", nilable: true, type: Array(String) },
        cmd: { key: "Cmd", nilable: true, type: Array(String) },
        entrypoint: { key: "Entrypoint", nilable: true, type: String },
        image: { key: "Image", type: String },
        labels: { key: "Labels", nilable: true, type: Hash(String, String) },
        volumes: { key: "Volumes", nilable: true, type: Hash(String, JSON::Any) },
        healthcheck: { key: "Healthcheck", nilable: true, type: HealthCheck },
        working_dir: { key: "WorkingDir", nilable: true, type: String },
        network_disabled: { key: "NetworkDisabled", nilable: true, type: Bool },
        mac_address: { key: "MacAddress", nilable: true, type: String },
        exposed_ports: { key: "ExposedPorts", nilable: true, type: Hash(String, JSON::Any) },
        stop_signal: { key: "StopSignal", nilable: true, type: String },
        host_config: { key: "HostConfig", nilable: true, type: HostConfig },
        networking_config: { key: "NetworkingConfig", nilable: true, type: Hash(String, JSON::Any) }
      }

      JSON.mapping({{PROPERTIES}})
      Util.initializer_for({{PROPERTIES}})

      class HealthCheck

        JSON.mapping(
          test: { key: "Test", nilable: true, type: Array(String) },
          interval: { key: "Interval", nilable: true, type: Int32 },
          timeout: { key: "Timeout", nilable: true, type: Int32 },
          retries: { key: "Retries", nilable: true, type: Int32 },
          start_period: { key: "StartPeriod", nilable: true, type: Int32 },
        )

      end

      class HostConfig

        JSON.mapping(
          binds: { key: "Binds", nilable: true, type: Array(String) },
          tmpfs: { key: "Tmpfs", nilable: true, type: Hash(String, String) },
          links: { key: "Links", nilable: true, type: Array(String) },
          memory: { key: "Memory", nilable: true, type: Int32 },
          memory_swap: { key: "MemorySwap", nilable: true, type: Int32 },
          memory_reservation: { key: "MemoryReservation", nilable: true, type: Int32 },
          kernel_memory: { key: "KernelMemory", nilable: true, type: Int32 },
          cpu_percent: { key: "CpuPercent", nilable: true, type: Int32 },
          cpu_shares: { key: "CpuShares", nilable: true, type: Int32 },
          cpu_period: { key: "CpuPeriod", nilable: true, type: Int32 },
          cpu_quota: { key: "CpuQuota", nilable: true, type: Int32 },
          cpuset_cpus: { key: "CpusetCpus", nilable: true, type: String },
          cpuset_mems: { key: "CpusetMems", nilable: true, type: String },
          io_maximum_bandwidth: { key: "IOMaximumBandwidth", nilable: true, type: Int32 },
          io_maximum_iops: { key: "IOMaximumIOps", nilable: true, type: Int32 },
          blkio_weight: { key: "BlkioWeight", nilable: true, type: Int32 },
          blkio_weight_device: { key: "BlkioWeightDevice", nilable: true, type: Array(NamedTuple(Path: String, Weight: Int32)) },
          blkio_device_read_bps: { key: "BlkioDeviceReadBps", nilable: true, type: Array(NamedTuple(Path: String, Rate: Int32)) },
          blkio_device_read_iops: { key: "BlkioDeviceReadIOps", nilable: true, type: Array(NamedTuple(Path: String, Rate: Int32)) },
          blkio_device_write_bps: { key: "BlkioDeviceWriteBps", nilable: true, type: Array(NamedTuple(Path: String, Rate: Int32)) },
          blkio_device_write_iops: { key: "BlkioDeviceWriteIOps", nilable: true, type: Array(NamedTuple(Path: String, Rate: Int32)) },
          memory_swappiness: { key: "MemorySwappiness", nilable: true, type: Int32 },
          oom_kill_disable: { key: "OomKillDisable", nilable: true, type: Bool },
          oom_score_adj: { key: "OomScoreAdj", nilable: true, type: Int32 },
          pid_mode: { key: "PidMode", nilable: true, type: String },
          pids_limit: { key: "PidsLimit", nilable: true, type: Int32 },
          port_bindings: { key: "PortBindings", nilable: true, type: Hash(String, NamedTuple(HostPort: String)) },
          publish_all_ports: { key: "PublishAllPorts", nilable: true, type: Bool },
          privileged: { key: "Privileged", nilable: true, type: Bool },
          readonly_rootfs: { key: "ReadonlyRootfs", nilable: true, type: Bool },
          dns: { key: "Dns", nilable: true, type: Array(String) },
          dns_options: { key: "DnsOptions", nilable: true, type: Array(String) },
          dns_search: { key: "DnsSearch", nilable: true, type: Array(String) },
          extra_hosts: { key: "ExtraHosts", nilable: true, type: Array(String) },
          volumes_from: { key: "VolumesFrom", nilable: true, type: Array(String) },
          cap_add: { key: "CapAdd", nilable: true, type: Array(String) },
          cap_drop: { key: "CapDrop", nilable: true, type: Array(String) },
          group_add: { key: "GroupAdd", nilable: true, type: Array(String) },
          restart_policy: { key: "RestartPolicy", nilable: true, type: NamedTuple(Name: String, MaximumRetryCount: Int32) },
          network_mode: { key: "NetworkMode", nilable: true, type: String },
          devices: { key: "Devices", nilable: true, type: NamedTuple(PathOnHost: String, PathInContainer: String) },
          sysctls: { key: "Sysctls", nilable: true, type: Hash(String, String) },
          ulimits: { key: "Ulimits", nilable: true, type: Hash(String, Int32) },
          log_config: { key: "LogConfig", nilable: true, type: NamedTuple(Type: String, Config: Hash(String, String)) },
          security_opt: { key: "SecurityOpt", nilable: true, type: Array(String) },
          storage_opt: { key: "StorageOpt", nilable: true, type: Hash(String, String) },
          cgroup_parent: { key: "CgroupParent", nilable: true, type: String },
          volume_driver: { key: "VolumeDriver", nilable: true, type: String },
          shm_size: { key: "ShmSize", nilable: true, type: Int32 },
        )

      end
    end
  end
end
