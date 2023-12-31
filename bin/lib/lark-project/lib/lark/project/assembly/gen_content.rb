# frozen_string_literal: true

module Lark
  module Project
    module Assembly
      require 'erb'
      require 'ostruct'

      # 生成 Assembly.swift 文件内容
      #
      # @param class_name [String] class name
      # @param items [Array<Item>] assembly items
      def self.gen_swift_content(class_name, items)
        # 记录同名的的 Assembly，以便根据需要加上 module 前缀
        dup_names = lambda {
          set = Set.new
          items.map(&:class).select { |e| set.add?(e).nil? }
        }.call.to_set

        template = File.read(File.expand_path('./resource/Assembly.swift', __dir__))
        hash = {
          :class_name => class_name,
          :import_pods => items.map(&:pod).uniq,
          :symbols => items.map do |item|
            cls = item.cls
            pod = item.pod
            !pod.nil? && dup_names.include?(cls) ? "#{pod}.#{cls}" : cls
          end
        }
        namespace = OpenStruct.new(hash).instance_eval { binding }
        ERB.new(template, trim_mode: '%<>').result(namespace)
      end
    end
  end
end
