module Docker::Types
  class Version
    JSON.mapping({
      platform: { key: "Platform", nilable: true, type: NamedTuple(Name: String) },
      components: { key: "Components", nilable: true, type: Array(Component) },
      version: { key: "Version", nilable: true, type: String },
      api_version: { key: "ApiVersion", nilable: true, type: String },
      min_api_version: { key: "MinApiVersion", nilable: true, type: String },
      git_commit: { key: "GitCommit", nilable: true, type: String },
      go_version: { key: "GoVersion", nilable: true, type: String },
      os: { key: "Os", nilable: true, type: String },
      arch: { key: "Arch", nilable: true, type: String },
      kernel_version: { key: "KernelVersion", nilable: true, type: String },
      build_time: { key: "BuildTime", nilable: true, type: String }
    })

    class Component

      JSON.mapping(
        name: { key: "Name", nilable: true, type: String },
        version: { key: "Version", nilable: true, type: String },
        details: { key: "Details", nilable: true, type: Hash(String, String) },
      )

    end
  end
end
