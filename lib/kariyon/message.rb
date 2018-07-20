require 'kariyon/package'
require 'kariyon/environment'

module Kariyon
  class Message < Hash
    def initialize(values)
      super
      values = exception_info(values) if values.is_a?(Exception)
      values.update({
        environment: Environment.name,
        package: {
          name: Package.name,
          version: Package.version,
        },
      })
      replace(values)
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
