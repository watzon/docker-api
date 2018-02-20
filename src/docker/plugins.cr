class Plugin

  JSON.mapping({
    id: { key: "Id", type: String, nilable: true },
    name: { key: "Name", type: String, nilable: true },
    tag: { key: "Tag", type: String, nilable: true },
    active: { key: "Active", type: Bool, nilable: true },
    config: { key: "Config", type: Config, nilable: true },
    manifest: { key: "Manifest", type: Manifest, nilable: true }
  })

  class Config

    JSON.mapping({
      mounts: { key: "Mounts", type: Array(Mount), nilable: true },
      env: { key: "Env", type: Array(String), nilable: true },
      args: { key: "Args", type: JSON::Any, nilable: true },
      devices: { key: "Devices", type: JSON::Any, nilable: true }
    })

    class Mount

      JSON.mapping({
        name: { key: "Name", type: String, nilable: true },
        description: { key: "Description", type: String, nilable: true },
        settable: { key: "Settable", type: JSON::Any, nilable: true },
        source: { key: "Source", type: String, nilable: true },
        destination: { key: "Destination", type: String, nilable: true },
        type: { key: "Type", type: String, nilable: true },
        options: { key: "Options", type: Array(String), nilable: true }
      })

    end

    class Device

      JSON.mapping({
        name: { key: "Name", type: String, nilable: true },
        description: { key: "Description", type: String, nilable: true },
        settable: { key: "Settable", type: JSON::Any, nilable: true },
        path: { key: "Path", type: String, nilable: true }
      })

    end

  end

  class Manifest

    JSON.mapping({
      manifest_version: { key: "ManifestVersion", type: String, nilable: true },
      description: { key: "Description", type: String, nilable: true },
      documentation: { key: "Documentation", type: String, nilable: true },
      interface: { key: "Interface", type: Interface, nilable: true },
      entrypoint: { key: "Entrypoint", type: Array(String), nilable: true },
      workdir: { key: "Workdir", type: String, nilable: true },
      user: { key: "User", type: Hash(String, JSON::Any), nilable: true },
      network: { key: "Network", type: Network, nilable: true },
      capabilities: { key: "Capabilities", type: JSON::Any, nilable: true },
      mounts: { key: "Mounts", type: Array(Plugin::Config::Mount), nilable: true },
      devices: { key: "Devices", type: Array(Plugin::Config::Device), nilable: true },
      env: { key: "Env", type: Array(Args), nilable: true },
      args: { key: "Args", type: Args, nilable: true }
    })

    class Interface

      JSON.mapping({
        types: { key: "Types", type: Array(String), nilable: true },
        socket: { key: "Socket", type: String, nilable: true }
      })

    end

    class Network

      JSON.mapping({
        type: { key: "Type", type: String, nilable: true }
      })

    end

    class Args

      JSON.mapping({
        name: { key: "Name", type: String, nilable: true },
        description: { key: "Description", type: String, nilable: true },
        settable: { key: "Settable", type: JSON::Any, nilable: true },
        value: { key: "Value", type: String | Array(String), nilable: true }
      })

    end

  end

end
