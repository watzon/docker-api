module Docker::Util

  # writes basic initializer from properti maps used by JSON.mapping
  # if a `mustbe` field is present for the value, the initializer will set the
  # instance variable to the given value
  macro initializer_for(properties)
    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(NamedTupleLiteral) %}
    {% end %}


    {% for key, value in properties %}
      {% if value[:mustbe] || value[:mustbe] == false %}
        @{{key.id}} : {{value[:type]}}
      {% end %}
    {% end %}
    def initialize(
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
      {% for key, value in properties %}
        {% if value[:mustbe] || value[:mustbe] == false %}
          @{{key.id}} = {{value[:mustbe]}}
        {% end %}
      {% end %}
    end
  end

  def self.build_auth_header(credentials)
    credentials = credentials.to_json if credentials.is_a?(Hash)
    encoded_creds = Base64.urlsafe_encode(credentials)
    {
      "X-Registry-Auth" => encoded_creds
    }
  end

  def self.build_config_header(credentials)
    if credentials.is_a?(String)
      credentials = JSON.parse(credentials)
    end

    header = {
      credentials["serveraddress"].to_s => {
        "username" => credentials["username"].to_s,
        "password" => credentials["password"].to_s,
        "email" => credentials["email"].to_s
      }
    }.to_json

    encoded_header = Base64.urlsafe_encode(header)

    {
      "X-Registry-Config" => encoded_header
    }
  end

end
