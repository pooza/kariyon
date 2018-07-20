require 'kariyon/package'
require 'kariyon/environment'

module Kariyon
  class Message < Hash
    def initialize(values)
      values = exception_info(values) if values.is_a?(Exception)
      super({
        environment: Environment.name,
        package: {
          name: Package.name,
          version: Package.version,
        },
      })
      update(values)
    end

    def exception_info(exception)
      return {
        class: exception.class,
        message: exception.message,
        backtrace: exception.backtrace[0..5],
      }
    end
  end
end
