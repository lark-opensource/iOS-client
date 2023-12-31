# frozen_string_literal: true

require 'logger'

module Lark
  # use for display message to user
  module UI
    # @return [Logger]
    def self.logger
      @logger ||= Logger.new($stderr).tap do |l|
        l.level = Logger::INFO
      end
    end
    def self.respond_to_missing?(*args)
      super.respond_to_missing?(*args) || logger.respond_to_missing?(*args)
    end
    # default to behavior like a logger
    def self.method_missing(method, *args, &block)
      logger.__send__(method, *args, &block)
    end

    # @!parse
    #  def self.debug(message); end
    #  def self.info(message); end
    #  def self.warn(message); end
    #  def self.error(message); end
    #  def self.fatal(message); end

    # will hold until call flush, normal use to show important message at end
    # and complete duplicate message will be trim. so only display once
    def self.warn_at_end(*message)
      (@logger_warn ||= Set.new).merge message
    end
    def self.warn_flush!
      @logger_warn&.each { |v| warn v }
      @logger_warn = nil
    end

    # print an long important message to user
    def self.multiline_notice(message)
      puts <<~MESSAGE
        \033[36m
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        #{message}

        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        \033[0m\n
      MESSAGE
    end
    # print an short notice message to user
    def self.notice(message)
      puts "\033[33m!#{message}\033[0m"
    end
  end
end
