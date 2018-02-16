module Docker
  class Container
    include Docker::Base

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
      creator = Types::Container::Creator.new(**opts)
      response = conn.post("/containers/create" + query.to_s, body: creator.to_json)
      hash = JSON.parse(response.body)
      new(conn, hash)
    end

    # Get a Container by its id.
    def self.get(id, opts : (Hash(String, _) | NamedTuple) = {} of String => String, conn = Docker.connection)
      container_json = conn.get("/containers/#{id}/json", body: opts.to_json).body
      hash = JSON.parse(container_json)
      new(conn, hash)
    end

    # Return all Containers.
    def self.all(opts : (Hash(String, _) | NamedTuple) = {} of String => String, conn = Docker.connection)
      response = conn.get("/containers/json", body: opts.to_json)
      hashes = JSON.parse(response.body)
      hashes.map { |hash| new(conn, hash) }
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
  end
end
