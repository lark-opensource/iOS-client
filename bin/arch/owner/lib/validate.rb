#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'net/http'
require 'cocoapods'
require_relative './config'
require_relative './utils'

module OwnerConfig
  class Validator
    # Owner 校验的入口方法
    #
    # @param [Array<Specification>] specs 工程中引入的所有 pod
    # @param [Boolean] silent 若为 true, 则不会展示校验结果
    # @param [Symbol] collect_error 是否收集未知的异常
    #   :none 不收集异常
    #   :sync 收集异常，并同步发送至 bot
    #   :async 收集异常，并异步发送至 bot，不阻塞当前进程
    def self.validate!(specs, silent: false, collect_error: :none)
      begin
        validate_specs!(specs)
        validate_pod_owner
        validate_extra_owner
      rescue OwnerConfigParseError => e
        validate_failed "解析失败: #{$!}"
        Utils.collect_error(e, mode: collect_error)
      rescue => e
        validate_failed "发生未知错误, #{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
        Utils.collect_error(e, mode: collect_error)
      end

      show_validate_result unless silent
    end

    private

    attr_accessor :notice_messages
    attr_accessor :warn_messages
    attr_accessor :error_messages

    # 校验 podspec 与 pod_owner.yml 是否相符
    # 若发现新增的 podspec, 会在 pod_owner.yml 中添加对应的初始值
    #
    # @param [Array<Specification>] specs
    def self.validate_specs!(specs)
      specs.each do |spec|
        pod_name = spec.name
        spec_authors = spec.authors || {}

        # 判断 pod 是否已经在 pod_owner.yml 里
        unless pods_config.pods.key?(pod_name)
          owners = spec_authors.values
                               .reject { |email| !email || email == 'email' }
                               .map { |email| email.delete_suffix('@bytedance.com') }

          is_owners_empty = owners.empty?
          is_summary_empty = (spec.summary.nil? || spec.summary.empty? || spec.summary == 'Required. 一句话描述该Pod功能')

          pods_config.add_pod!(name: spec.name,
                               owners: is_owners_empty ? [MARK_TODO] : owners,
                               summary: is_summary_empty ? nil : spec.summary)
          validate_failed("检测到新增的 pod: #{pod_name}, 请在 pod_owner.yml 文件中搜索字符串 '#{MARK_TODO}' 并补充配置信息")
        end
      end
    end

    # 校验 pod_owner.yml 中的内容是否正确
    def self.validate_pod_owner
      pods_config.pods.each do |pod_name, pod|
        unless pods_config.team_options.include?(pod.team)
          validate_failed("pod_owner.yml:#{pod_name} 中的 team 字段不合法: \"#{pod.team}\"")
        end

        if pod.owners.empty?
          validate_failed("pod_owner.yml:#{pod_name} 中的 owners 数组不能为空")
        elsif (name = pod.owners.find { |owner| owner.include?('@') })
          validate_failed("pod_owner.yml:#{pod_name} 中的 owners 不能带有邮箱后缀: #{name}")
        elsif (name = pod.owners.find { |owner| owner.include?(MARK_TODO) })
          validate_failed("pod_owner.yml:#{pod_name} 中的 owners 未完成配置: #{name}")
        end
      end
    end

    # 校验 extra_owner.yml 中的内容是否正确
    def self.validate_extra_owner
      custom_config
        .flattened_pattern_to_rule
        .each { |_, rule|
          owners = rule.owners
          if owners.nil? || owners.empty?
            validate_failed("extra_owner.yml: owners 不能为空, rule: #{rule.inspect}")
          elsif (name = owners.find { |name| name.include?('@') })
            validate_failed("extra_owner.yml: owners 不能带有邮箱后缀: #{name} rule: #{rule.inspect}")
          end

          rule.pattern
        }
    end

    def self.pods_config
      path = File.expand_path('config/pod_owner.yml', Utils.project_root)
      # noinspection RbsMissingTypeSignature
      @cached_pods_config ||= PodsConfig.load_file(path)
    end

    def self.custom_config
      path = File.expand_path('config/extra_owner.yml', Utils.project_root)
      # noinspection RbsMissingTypeSignature
      @cached_custom_config ||= ExtraConfig.load_file(path)
    end

    # 收集 validate 过程中的通知信息
    def self.validate_notice(message)
      @notice_messages ||= []
      @notice_messages << message
    end

    # 收集 validate 过程中的警告信息
    def self.validate_warning(message)
      @warn_messages ||= []
      @warn_messages << message
    end

    # 收集 validate 过程中的错误信息
    def self.validate_failed(message)
      @error_messages ||= []
      @error_messages << message
    end

    def self.show_validate_result
      # 三个变量都为 nil 则不输出任何信息
      return unless @notice_messages || @warn_messages || @error_messages
      puts("\n")

      @notice_messages&.each do |message|
        puts("[Owner][NOTICE] #{message}".green)
      end

      @warn_messages&.each do |message|
        puts("[Owner][WARN] #{message}".yellow)
      end

      unless @error_messages.nil? || @error_messages.empty?
        @error_messages.each do |message|
          puts("[Owner][ERROR] #{message}".red)
        end

        puts("Owner 校验失败，请检查上述原因，详情参考: https://bytedance.feishu.cn/wiki/BjlFwNVvAiq6NYkT9prcTzQNnIe，有任何疑问随时联系 lihaozhe.12@bytedance.com\n".red)

        raise(Pod::Informative, "Owner 校验失败")
      end

      puts("\n")
    end
  end
end

module Pod
  class Podfile
    # @param [Array<Specification>] specs 工程中引入的所有 podspec
    def validate_owner_config!(specs)
      specs = specs.reject { |spec| spec.name.include?('/') } # 忽略 subspec
      # 现阶段静默验证，并异步收集未知异常发送至 bot，一段时间后再开启卡点
      OwnerConfig::Validator.validate!(specs, silent: true, collect_error: :async)
    end
  end
end
