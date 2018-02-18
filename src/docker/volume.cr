module Docker
  class Volume

    JSON.mapping({
      name: { key: "Name", type: String },
      driver: { key: "Driver", type: String },
      mountpoint: { key: "Mountpoint", type: String },
      status: { key: "Status", type: Hash(String, String) },
      labels: { key: "Labels", type: Hash(String, String) },
      scope: { key: "Scope", type: String }
    })

  end

end
