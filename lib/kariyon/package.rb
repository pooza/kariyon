module Kariyon
  module Package
    def environment_class
      return 'Kariyon::Environment'.constantize
    end

    def package_class
      return 'Kariyon::Package'.constantize
    end

    def config_class
      return 'Kariyon::Config'.constantize
    end

    def logger_class
      return 'Kariyon::Logger'.constantize
    end

    def self.name
      return 'kariyon'
    end

    def self.version
      return Config.instance['/package/version']
    end

    def self.url
      return Config.instance['/package/url']
    end

    def self.full_name
      return "#{name} #{version}"
    end

    def self.user_agent
      return "#{name}/#{version} (#{url})"
    end
  end
end
