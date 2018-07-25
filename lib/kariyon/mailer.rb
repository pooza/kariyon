require 'kariyon/environment'
require 'kariyon/package'
require 'kariyon/config'
require 'mail'
require 'json'

module Kariyon
  class Mailer
    attr_accessor :subject_prefix

    def initialize
      @config = Config.instance
      @mail = ::Mail.new(charset: 'UTF-8')
      @mail['X-Mailer'] = Package.user_agent
      @mail.from = "root@#{Environment.name}"
      @mail.to = @config['local']['mail']['to']
      @mail.delivery_method(:sendmail)
      @subject_prefix = "[#{Package.name}] #{Environment.name}"
    end

    def subject
      return @mail.subject
    end

    def subject=(value)
      @mail.subject = "#{@subject_prefix} #{value}"
    end

    def from
      return @mail.from
    end

    def from=(value)
      @mail.from = value
    end

    def to
      return @mail.to
    end

    def to=(value)
      @mail.to = value
    end

    def body
      return @mail.body
    end

    def body=(value)
      value = JSON.pretty_generate(value) if value.is_a?(Hash)
      @mail.body = value
    end

    def priority
      return @mail['X-Priority']
    end

    def priority=(value)
      @mail['X-Priority'] = value
    end

    def deliver
      @mail.deliver!
    end
  end
end
