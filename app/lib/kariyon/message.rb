module Kariyon
  class Message < Hash
    def initialize(values)
      super
      if values.is_a?(Exception)
        self[:class] = values.class
        self[:message] = values.message
        self[:backtrace] = values.backtrace[0..5]
      else
        update(values)
      end
      self[:service] = Environment.name
      self[:package] = {
        name: Package.name,
        version: Package.version,
      }
    end
  end
end
