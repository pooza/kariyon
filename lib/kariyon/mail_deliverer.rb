require 'kariyon/environment'
require 'mail'

module Kariyon
  class MailDeliverer
    def initialize
      @mail = Mail.new(charset: 'UTF-8')
      @mail['X-Mailer'] = self.class.name
      @mail.from = "root@#{Kariyon::Environment.name}"
      @mail.to = "admin@#{Kariyon::Environment.name}"
      @mail.delivery_method(:sendmail)
    end

    def subject
      return @mail.subject
    end

    def subject= (value)
      @mail.subject = "#{Kariyon::Environment.name} #{value}"
    end

    def to
      return @mail.to
    end

    def to= (value)
      @mail.to = value
    end

    def body
      return @mail.body
    end

    def body= (value)
      @mail.body = value
    end

    def priority
      return @mail['X-Priority']
    end

    def priority= (value)
      @mail['X-Priority'] = value
    end

    def deliver!
      @mail.deliver!
    end
  end
end
