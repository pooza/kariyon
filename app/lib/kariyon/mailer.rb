module Kariyon
  class Mailer < Ginseng::Mailer
    include Package

    def default_prefix
      return Package.name
    end
  end
end
