module Docker::Types
  class Container
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
    Util.initializer_for({{PROPERTIES}})

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

    class Creator

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
