module Kariyon
  class Mailer < Ginseng::Mailer
    include Package

    def default_receipt
      return config['/mail/to']
    end
  end
end
