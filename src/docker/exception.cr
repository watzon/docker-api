# This module holds the Exceptions for the shard.
module Docker::Exception

  # The default error. It's never actually raised, but can be used to catch all
  # shard-specific errors that are thrown as they all subclass from this.
  class DockerException < ::Exception; end

  # Raised when invalid arguments are passed to a method.
  class ArgumentException < DockerException; end

  # Raised when a request returns a 400.
  class ClientException < DockerException; end

  # Raised when a request returns a 401.
  class UnauthorizedException < DockerException; end

  # Raised when a request returns a 404.
  class NotFoundException < DockerException; end

  # Raised when a request returns a 409.
  class ConflictException < DockerException; end

  # Raised when a request returns a 500.
  class ServerException < DockerException; end

  # Raised when there is an unexpected response code / body.
  class UnexpectedResponseException < DockerException; end

  # Raised when there is an incompatible version of Docker.
  class VersionException < DockerException; end

  # Raised when a request times out.
  class TimeoutException < DockerException; end

  # Raised when login fails.
  class AuthenticationException < DockerException; end

  # Raised when an IO action fails.
  class IOException < DockerException; end
end
