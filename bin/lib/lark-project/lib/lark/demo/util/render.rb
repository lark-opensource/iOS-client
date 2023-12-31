module Lark
  module Demo
    module Utils
      require 'erb'
      require 'ostruct'

      # Render template with params
      #
      # @type template [String]
      # @type hash [Hash]
      def self.render(template, hash)
        namespace = OpenStruct.new(hash).instance_eval { binding }
        ERB.new(template, trim_mode: '%<>').result(namespace)
      end
    end
  end
end
