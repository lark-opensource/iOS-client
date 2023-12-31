# frozen_string_literal: true

require_relative 'lark/command/synclock'
require_relative 'lark/project/integration/bits'
require_relative 'cocoapods_bug_patch'

module Pod
  module Xcode
    class LinkageAnalyzer
      def self.dynamic_binary?(binary)
        @cached_dynamic_binary_results ||= {}
        return @cached_dynamic_binary_results[binary] unless @cached_dynamic_binary_results[binary].nil?
        return false unless binary.file?

        name = File.basename(binary)
        @cached_dynamic_binary_results[binary] = if name.include? 'RustPB' or name.include? 'liblark'
                                                   # 这个方法大量调用好像有性能问题？改用MachO判断
                                                   `file '#{binary}'`.include? 'dynamic'
                                                 else
                                                   MachO.open(binary).dylib?
                                                 end
      rescue MachO::MachOError
        @cached_dynamic_binary_results[binary] = false
        # MachO.open(binary).dylib? 有兼容性问题，可能抛出异常
      end
    end
  end
  class Podfile
    initialize_method = instance_method(:initialize)
    define_method(:initialize) do |*args, &block|
      initialize_method.bind(self).call(*args, &block)
      # 自动调用延后的action
      flush_defer_actions! if respond_to? :flush_defer_actions!
    end
  end

  class PodTarget
    def only_swift?
      # if %w[OPGadget].include? name
      #   return false
      # end
      return @only_swift if defined? @only_swift
      accessors = file_accessors.select { |fa| fa.spec.library_specification? }
      source_files = accessors.flat_map(&:source_files)

      @only_swift = accessors.flat_map(&:headers).empty? && !source_files.any? { |file| !file.to_s.end_with? ".swift" }
    end
  end

  class Sandbox
    def clean_pod(name, pod_dir)
      pod_dir.rmtree if pod_dir&.exist?
      podspec_path = specification_path(name)
      podspec_path.rmtree if podspec_path&.exist? && !local?(name)
      pod_target_project_path = pod_target_project_path(name)
      pod_target_project_path.rmtree if pod_target_project_path&.exist?
    end
  end

  class Specification
    old_platform_hash_3721 = instance_method(:platform_hash)
    define_method :platform_hash do |*args, &block|
      result = old_platform_hash_3721.bind(self).call(*args, &block)
      if !result.empty? and !result.include?("visionos")
        result["visionos"] = '1.0'
      end
      result
    end
  end

  module Generator
    class Header
      def generate_platform_import_header
        case platform.name
        when :ios, :tvos, :visionos then "#import <UIKit/UIKit.h>\n"
        when :osx then "#import <Cocoa/Cocoa.h>\n"
        else "#import <Foundation/Foundation.h>\n"
        end
      end
    end
  end

  class Platform
    old_initialize_3721 = instance_method(:initialize)
    define_method :initialize do |*args, &block|
      if args[0].is_a?(String) and args[0] == "xros"
        args[0] = "visionos"
      end

      old_initialize_3721.bind(self).call(*args, &block)
    end
  end
end
