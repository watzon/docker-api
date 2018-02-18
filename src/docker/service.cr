module Docker
  class Service

    JSON.mapping({
      name: { key: "Name", nilable: true, type: String },
      task_template: { key: "TaskTemplate", nilable: true, type: TaskTemplate },
      mode: { key: "Mode", nilable: true, type: Mode },
      update_config: { key: "UpdateConfig", nilable: true, type: UpdateConfig },
      endpoint_spec: { key: "EndpointSpec", nilable: true, type: EndpointSpec },
      labels: { key: "Labels", nilable: true, type: Hash(String, String) }
    })

    class TaskTemplate

      JSON.mapping({
        container_spec: { key: "ContainerSpec", nilable: true, type: ContainerSpec },
        networks: { key: "Networks", nilable: true, type: Array(Hash(String, String)) },
        log_driver: { key: "LogDriver", nilable: true, type: LogDriver },
        placement: { key: "Placement", nilable: true, type: Placement },
        resources: { key: "Resources", nilable: true, type: Resources },
        restart_policy: { key: "RestartPolicy", nilable: true, type: RestartPolicy }
      })

      class ContainerSpec

        JSON.mapping({
          image: { key: "Image", nilable: true, type: String },
          mounts: { key: "Mounts", nilable: true, type: Array(Mount) },
          user: { key: "User", nilable: true, type: String }
        })

        class Mount

          JSON.mapping({
            read_only: { key: "ReadOnly", nilable: true, type: Bool },
            source: { key: "Source", nilable: true, type: String },
            target: { key: "Target", nilable: true, type: String },
            type: { key: "Type", nilable: true, type: String },
            volume_options: { key: "VolumeOptions", nilable: true, type: VolumeOptions }
          })

          class VolumeOptions

            JSON.mapping({
              driver_config: { key: "DriverConfig", nilable: true, type: DriverConfig },
              labels: { key: "Labels", nilable: true, type: Hash(String, String) }
            })

          end

        end

      end

      class LogDriver

        JSON.mapping({
          name: { key: "Name", nilable: true, type: String },
          options: { key: "Options", nilable: true, type: Hash(String, String) }
        })

      end

      class Placement

        JSON.mapping({
          constraints: { key: "Constraints", nilable: true, type: Array(String) }
        })

      end

      class Resources

        JSON.mapping({
          limits: { key: "Limits", nilable: true, type: Limits },
          reservations: { key: "Reservations", nilable: true, type: Reservations }
        })

        class Limits

          JSON.mapping({
            nano_cpus: { key: "NanoCPUs", nilable: true, type: Int32 },
            memory_bytes: { key: "MemoryBytes", nilable: true, type: Int32 }
          })

        end

      end

      class RestartPolicy

        JSON.mapping({
          condition: { key: "Condition", nilable: true, type: String },
          delay: { key: "Delay", nilable: true, type: Int64 },
          max_attempts: { key: "MaxAttempts", nilable: true, type: Int32 }
        })

      end

    end

    class Mode

      JSON.mapping({
        replicated: { key: "Replicated", nilable: true, type: Replicated }
      })

      class Replicated

        JSON.mapping({
          replicas: { key: "Replicas", nilable: true, type: Int32 }
        })

      end

    end

    class UpdateConfig

      JSON.mapping({
        delay: { key: "Delay", nilable: true, type: Int64 },
        parallelism: { key: "Parallelism", nilable: true, type: Int32 },
        failure_action: { key: "FailureAction", nilable: true, type: String }
      })

    end

    class EndpointSpec

      JSON.mapping({
        mode: { key: "Mode", nilable: true, type: String },
        ports: { key: "Ports", nilable: true, type: Array(Port) }
      })

      class Port

        JSON.mapping({
          protocol: { key: "Protocol", nilable: true, type: String },
          published_port: { key: "PublishedPort", nilable: true, type: Int32 },
          target_port: { key: "TargetPort", nilable: true, type: Int32 }
        })

      end

    end

  end
end
