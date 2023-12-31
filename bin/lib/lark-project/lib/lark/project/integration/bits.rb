# frozen_string_literal: true

# 本文件负责和bits相关的插件做集成

return unless defined?(Bundler)
require 'cocoapods'
require 'cocoapods-remote-resolve'
require 'pod/command/update_lock'

module Pod
  class Command
    module CocoapodsRemoteResolveLarkMixin
      # @param argv [CLAide::ARGV]
      def initialize(argv)
        # flag?会消耗参数... 坑
        check_argv = Marshal.load(Marshal.dump(argv))
        if rr_argv_flag?('enable', argv: check_argv, default: nil).nil? &&
           rr_argv_flag?('cdn-source', argv: check_argv, default: nil).nil?
          # 有更新时使用远端判决，默认使用更快的本地可用的CDN Source
          # NOTE: 测试发现CDN只有首次update要下载全量的数据比较慢，后续都比远端判决快。
          # 另外CDN的兼容性会更好。所有本地研发环境都用cdn, CI可能有新机器，缓存命中低，使用云端判决
          # if !ENV['WORKFLOW_JOB_ID'].nil? && (is_a?(Update) || (is_a?(UpdateLock) && has_update?))
          #   argv.instance_variable_get(:@entries).insert 0, *CLAide::ARGV::Parser.parse(['--rr-enable'])
          # else
            argv.instance_variable_get(:@entries).insert 0, *CLAide::ARGV::Parser.parse(['--rr-cdn-source'])
          # end
        end
        # 远端判决后，repo不用更新了，这样二进制仓库会得不到更新
        # 但是使用远端判决的话，repo-update会更新所有的仓库，起不到减轻硬盘的作用
        if is_a?(Install) && check_argv.flag?('repo-update').nil? &&
           (!(p = config.sandbox.manifest_path).exist? || Time.now - p.mtime > 3600)
          argv.instance_variable_get(:@entries).insert 0, *CLAide::ARGV::Parser.parse(['--repo-update'])
        end
        super(argv)
      end
    end
    class Install
      include CocoapodsRemoteResolveLarkMixin
    end

    class Update
      include CocoapodsRemoteResolveLarkMixin
    end

    class UpdateLock
      def has_update? # rubocop:disable all
        @pods.any? || @excluded_pods.any? || @source_pods.any? || @all_update
      end
      include CocoapodsRemoteResolveLarkMixin
    end

    class AppCache
      if defined? ::CocoapodsRemoteResolve
        include ::CocoapodsRemoteResolve::ConfigurationHelper::InstanceMethods
        extend ::CocoapodsRemoteResolve::ConfigurationHelper::ClassMethods
      end
      include CocoapodsRemoteResolveLarkMixin
    end
  end
end
