module Docker
  # This class represents a Docker Event.
  class Event

    PROPERTIES = {
      status: { type: String },
      id: { type: String },
      from: { type: String },
      type: { key: "Type", type: String },
      action: { key: "Action", type: String },
      actor: { key: "Actor", type: Actor },
      time: { type: Int32 },
      time_nano: { key: "timeNano", type: Int64 }
    }

    JSON.mapping({{PROPERTIES}})
    Util.initializer_for({{PROPERTIES}})

    def self.stream(opts = {} of String => String, conn = Docker.connection)
      query = "?" + HTTP::Params.encode(opts) unless opts.empty?
      conn.get("/events" + query.to_s)
    end

    def self.since(since, opts = {} of String => String, conn = Docker.connection, &block)
      stream(opts.merge({ "since" => since }), conn)
    end

    # Represents the actor object nested within an event
    class Actor

      PROPERTIES = {
        id: { key: "ID", type: String },
        attributes: { key: "Attributes", type: Hash(String, String) }
      }

      JSON.mapping({{PROPERTIES}})
      Util.initializer_for({{PROPERTIES}})

    end
  end
end
