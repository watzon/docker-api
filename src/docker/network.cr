module Docker
  class Network

    JSON.mapping({
      name: { key: "Name", type: String },
      id: { key: "Id", type: String },
      scope: { key: "Scope", type: String },
      driver: { key: "Driver", type: String },
      enable_i_pv_6: { key: "EnableIPv6", type: Bool },
      ipam: { key: "IPAM", type: Ipam },
      internal: { key: "Internal", type: Bool },
      containers: { key: "Containers", type: Hash(String, Container) },
      options: { key: "Options", type: Hash(String, String) },
      labels: { key: "Labels", type: Hash(String, String) }
    })

    class Ipam

      JSON.mapping({
        driver: { key: "Driver", type: String },
        config: { key: "Config", type: Array(Config) },
        options: { key: "Options", type: Hash(String, String) }
      })

      class Config

        JSON.mapping({
          subnet: { key: "Subnet", type: String },
          gateway: { key: "Gateway", type: String }
        })

      end

    end

    class Container

      JSON.mapping({
        name: { key: "Name", type: String },
        endpoint_id: { key: "EndpointID", type: String },
        mac_address: { key: "MacAddress", type: String },
        i_pv_4_address: { key: "IPv4Address", type: String },
        i_pv_6_address: { key: "IPv6Address", type: String }
      })

    end

  end
end
