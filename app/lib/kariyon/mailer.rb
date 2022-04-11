module Kariyon
  class Mailer < Ginseng::Mailer
    def default_prefix
      return Package.name
    end

    def default_receipt
      return Config.instance['/mail/to']
    end
  end
end
