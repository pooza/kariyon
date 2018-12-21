module Kariyon
  module Package
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
      return "#{name} #{version} #{url}"
    end
  end
end
