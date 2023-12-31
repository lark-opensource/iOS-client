# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'
require 'json'
require 'open-uri'
require 'tmpdir'
require 'uri'
require 'digest'
require 'fileutils'
require 'EEScaffold'
require 'net/http'
require 'find'
require 'plist'
require 'zip'
require_relative 'environment'
require_relative 'utils'

module Lark
  module Project
    class ToolChainManager
      @instance = new

      private_class_method :new
      class << self
        attr_reader :instance
      end

      @@status = {
        env: {},
        toolchain: {
          lldb: :not_exist,
          coverage: :not_exist,
          hotfix: :not_exist,
          evil_method: :not_exist,
          frame_outlining: :not_exist,
          gmo: :not_exist,
          zip_ld: :not_exist,
          lark_lld: :not_exist,
          lark_kunld: :not_exist,
          lark_compiler_driver: :not_exist
        }
      }
      @@lark_toolchain_tips = []

      attr_reader :toolchain_config, :toolchain_setting, :online_toolchain_setting, :evil_method_config, :global_machine_outlining_list, :current_app_version, :hotpatch_list
      attr_accessor :exist_toolchains, :exist_lldbs, :consumed_modules, :driver_modules, :podfile_dir

      def snapshot_current_state
        Logger.info("ENV: \n#{ENV.to_hash.to_json}")
        Logger.info("ToolChainStatus: \n#{@@status.to_json}")
        Logger.info("ToolChains: \n#{exist_toolchains.to_json}")
      end

      def setup_toolchain(podfile)
        add_toolchain_tips("Lark工程现在已支持自定义的工具链配置, 现在你可以自定义链接器和配置lldb了，配置和说明在 ~/.lark_toolchain/setting.toml".green)
        # 设置podfile路径
        self.podfile_dir = File.dirname(podfile.defined_in_file)

        if $lark_env.local?
          skip_lldb_download = toolchain_setting.fetch(:skip_lldb_download.to_s, {}).fetch(:default.to_s, false)
          clean_lldb_space = toolchain_setting.fetch(:clean_lldb_space.to_s, {}).fetch(:default.to_s, false)
          unless skip_lldb_download
            setup_lldb(podfile, $lark_env.force_disable_statistic?)
          else
            add_toolchain_tips("当前内网LLDB未下载，若要启用请在配置文件中打开".red)
          end
          clean_lldb if clean_lldb_space
          devdir = `xcode-select -p`
          add_toolchain_tips("Active developer directory is #{devdir}".blue)
        end
        return if toolchain_config.nil?

        setup_toolchain_unify if $lark_env.code_coverage_enable || $lark_env.hotpatch_enable || $lark_env.evil_method_enable || $lark_env.frame_outlining_enable || $lark_env.global_machine_outlining_summary_emit || $lark_env.global_machine_outlining_summary_consume
        setup_gmo_summary if $lark_env.global_machine_outlining_summary_consume
        if $lark_env.global_machine_outlining_summary_emit && @@status[:toolchain][:hotfix] == :exist
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          toolchain_bundle_id = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          Logger.info("设置bits环境变量 LARK_TOOLCHAIN_BUNDLE_ID为#{toolchain_bundle_id}")
          system "bit env set LARK_TOOLCHAIN_BUNDLE_ID #{@toolchain_bundle_id}"
        end

        # 清理gmo文件夹
        if $lark_env.global_machine_outlining_summary_emit
          workspace = ENV.fetch("WORKSPACE", File.join(File.dirname(__FILE__), '../../../../../..'))
          gmobase_path = "#{workspace}/Pods/gmo-base"
          FileUtils.rm_rf(gmobase_path) if Dir.exist?(gmobase_path)
          FileUtils.mkdir_p(gmobase_path)
        end

        ## 本地读取setting.toml的linker配置, 强制设置
        local_linker_setting_hook
        if $lark_env.zip_text_ld_enable
          setup_zip_ld
        elsif $lark_env.lark_lld_enable or $lark_env.lark_kunld_enable or $lark_env.lark_jild_enable
          setup_custom_ld
        end
        if $lark_env.lark_compiler_driver_enable
          setup_compiler_driver
        end
      ensure
        update_env_and_report
        Pod::UI.warn('Lark Toolchain'.green, @@lark_toolchain_tips)
      end

      def toolchain_setting
        if @toolchain_setting.nil?
          # 初始化为控，如果线上更新失败，后续使用setting的兜底default值来完成工程配置
          @toolchain_setting = Hash.new
          require 'toml'
          toolchain_setting_path = File.expand_path('~/.lark_toolchain/setting.toml')
          setting_updated = false # 写入、更新、迁移都需要更新本地配置问题
          should_setting_update = false
          unless File.exist?(toolchain_setting_path)
            should_setting_update = true
          else
            @toolchain_setting = TOML.load_file(toolchain_setting_path)
            should_setting_update = true if @toolchain_setting.fetch(:auto_sync.to_s, {}).fetch(:enable.to_s, true)
          end

          if should_setting_update && !online_toolchain_setting.empty?
            setting_updated = true
            @toolchain_setting = online_toolchain_setting
          end

          setting_updated ||= migrating_toolchain_setting # 第一次初始化的时候迁移, 返回是否迁移标志

          if setting_updated
            toolchain_setting_dir = File.expand_path('~/.lark_toolchain')
            FileUtils.mkdir_p(toolchain_setting_dir) unless File.directory?(toolchain_setting_dir)
            toolchain_setting_str = TOML::Generator.new(@toolchain_setting).body
            File.open(File.expand_path(toolchain_setting_path), 'w') do |fd|
              fd.write(toolchain_setting_str)
            end  
          end
        end

        @toolchain_setting
      end

      # 返回是否迁移，如果有迁移动作，则后续步骤将迁移的配置写入文件
      def migrating_toolchain_setting
        return false if @toolchain_setting.empty?

        update = false
        online_toolchain_setting.each do |key, value|
          if !@toolchain_setting.key?(key)
            @toolchain_setting[key] = online_toolchain_setting[key]
            update = true
          else
            # 如果线上的描述有更新，同步
            if key != "version" && @toolchain_setting[key][:Description.to_s] != online_toolchain_setting[key][:Description.to_s]
              @toolchain_setting[key][:Description.to_s] = online_toolchain_setting[key][:Description.to_s]
              update = true
            end
          end
        end
        @toolchain_setting[:version.to_s] = online_toolchain_setting[:version.to_s] if update

        return update
      end

      def local_linker_setting_hook
        if $lark_env.local?
          linker_type = toolchain_setting.fetch(:linker.to_s, {}).fetch(:default.to_s, 'kunld').to_sym
          ENV['LARK_JILD_ENABLE'] = 'false'
          ENV['LARK_KUNLD_ENABLE'] = 'false'
          ENV['LARK_LLD_ENABLE'] = 'false'
          Logger.info("本地toolchain配置的linker是#{linker_type}")
          add_toolchain_tips("本地toolchain配置的linker是#{linker_type}".green)
          case linker_type
          when :jild 
            ENV['LARK_JILD_ENABLE'] = 'true'
          when :kunld 
            ENV['LARK_KUNLD_ENABLE'] = 'true'
          when :lld 
            ENV['LARK_LLD_ENABLE'] = 'true'
          when :default
            return
          else
            raise "[LarkToolChain] unsupported linker #{linker_type}"
          end
        end
      end

      def noti_or_switch_lldb
        current_toolchain_bundle_id = Utils.current_toolchain_bundle_id
        auto_switch_lldb = toolchain_setting.fetch(:auto_switch_lldb.to_s, {}).fetch(:enable.to_s, false)
        Logger.info("自动切换lldb: #{auto_switch_lldb}")
        # 使用默认工具链的，且未设置自动切换，无需提示，也无需重启
        return if current_toolchain_bundle_id.empty? && !auto_switch_lldb

        current_lldb = File.basename(Utils.dancecc_toolchain_path)

        is_current_lldb_exist = Utils.toolchains.include?(current_lldb)
        if auto_switch_lldb
          if is_current_lldb_exist
            return if Utils.toolchains[current_lldb][:bundle_id.to_s] == current_toolchain_bundle_id #如果已经设置对，则无需处理
            Utils.set_current_toolchain(Utils.toolchains[current_lldb][:bundle_id.to_s])
            Logger.info("设置 toolchain 的 bundle ID 为 #{Utils.toolchains[current_lldb][:bundle_id.to_s]}")
          else
            return if current_toolchain_bundle_id.empty? #如果本来就没配置，直接返回，无需后续的恢复及重启操作
            Utils.reset_current_toolchain
            Logger.info("恢复 toolchain 为默认")
          end
          Utils.restart_xcode
        else
          if is_current_lldb_exist
            return if Utils.toolchains[current_lldb][:bundle_id.to_s] == current_toolchain_bundle_id
          end
          add_toolchain_tips("当前lldb与Xcode版本不匹配, 请通过 Xcode -> Toolchains 重新选择".red)
        end
      end

      def setup_lldb(podfile, force_disable_statistic = false)
        require 'cocoapods-dancecc-toolchain'
        # Xcode15后不使用dancecc-toolchain分发lldb
        if Pod::Version.new(Lark::Project::Utils.current_xcode_version) < Pod::Version.new('15.0')
          podfile.use_dancecc_toolchain('lldb') do |_ctx|
            features = {}
            features[:lldb_statistics] = !force_disable_statistic
            features[:lldb_override_default] = false
            features[:lldb_install_rust_formatter] = ENV['RUST_SDK_LOCAL_DEV'].to_s == 'true'
            Logger.info("dancecc_toolchain features: #{features}")
            features
          end
          @@status[:toolchain][:lldb] = :exist  
        else
          add_toolchain_tips('[DanceCC/LLDB] Instructions for using custom lldb toolchain: https://bytedance.feishu.cn/wiki/wikcnjtmsVlCDS553O1Pj261SHe'.green)
        end
        download_rust_lldb = toolchain_setting.fetch(:download_rust_lldb.to_s, {}).fetch(:default.to_s, false)
        setup_lldb_bypass
        if download_rust_lldb
          setup_rust_lldb
        else
          DanceCC::LLDBToolChainManager.update_lldbinit(false, 'command script import "~/.dancecc/rust.py"', 'Rust Formatter')
        end

        setup_lldb_statistic unless force_disable_statistic
        update_lldb_init_file(podfile.defined_in_file)
        revoke_lldb_patch
        patch_lldb_toolchain if $lark_env.lark_patch_dancecc_lldb
        noti_or_switch_lldb
      end

      def clean_lldb
        require 'cocoapods-dancecc-toolchain'
        exist_lldbs.each do |bundle_id, path|
          version = "#{DanceCC::Utils.swift_version}"
          unless path.include?(version)
            FileUtils.rm_rf(path)
            Logger.info("正在清理LLDB：#{path}")
          end
        end
      end

      def setup_lldb_bypass
        require 'cocoapods-dancecc-toolchain'
        unless toolchain_config[:lldb_bypass.to_s].include?(Utils.current_xcode_version)
          add_toolchain_tips("The corresponding Xcode-#{Utils.current_xcode_version} of the lldb toolchain was not found, skip".yellow)
          return
        end

        unless toolchain_config[:lldb_bypass.to_s][Utils.current_xcode_version][:bypass.to_s]
          Logger.info("lark lldb bypass disable")
          return
        end
        version = DanceCC::Utils.swift_version
        url = toolchain_config[:lldb_bypass.to_s][Utils.current_xcode_version][:url.to_s]
        md5 = toolchain_config[:lldb_bypass.to_s][Utils.current_xcode_version][:md5.to_s]
        DanceCC::LLDBToolChainManager.config_toolchain(version, url, md5)
      end

      def setup_rust_lldb
        require 'cocoapods-dancecc-toolchain'
        unless toolchain_config[:rust_lldb.to_s].include?(Utils.current_xcode_version)
          add_toolchain_tips("The corresponding Xcode-#{Utils.current_xcode_version} of the rust lldb toolchain was not found, skip".yellow)
          return
        end

        version = DanceCC::Utils.swift_version
        url = toolchain_config[:rust_lldb.to_s][Utils.current_xcode_version][:url.to_s]
        md5 = toolchain_config[:rust_lldb.to_s][Utils.current_xcode_version][:md5.to_s]
        DanceCC::LLDBToolChainManager.config_toolchain("#{version}-rust", url, md5)
        add_toolchain_tips("支持Rust调试的LLDB已配置，LLDB名字带\"4Rust\"，速度比非Rust版会慢一点，请按需取用".green)
        local_rust_formatter_path = File.expand_path('~/.dancecc/rust.py')
        FileUtils.mkdir_p(File.dirname(local_rust_formatter_path)) unless Dir.exist?(File.dirname(local_rust_formatter_path))
        DanceCC::LLDBToolChainManager.download("http://tosv.byted.org/obj/toutiao.ios.arch/llvm-infrastructure-tools/dancecc/rust.py", local_rust_formatter_path) unless File.exist?(local_rust_formatter_path)
        DanceCC::LLDBToolChainManager.update_lldbinit(true, 'command script import "~/.dancecc/rust.py"', 'Rust Formatter')
      end

      def setup_lldb_statistic
        require 'cocoapods-dancecc-toolchain'
        current_xcode_version = toolchain_config[:lldb_statistics.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
        url = toolchain_config[:lldb_statistics.to_s][current_xcode_version][:url.to_s]
        md5 = toolchain_config[:lldb_statistics.to_s][current_xcode_version][:md5.to_s]
        DanceCC::LLDBToolChainManager.config_statistics(url, md5)
        DanceCC::LLDBToolChainManager.update_lldbinit(true, 'command script import "~/.dancecc/dancecc_lldb.py"', '[DanceCC]LLDB性能统计 https://bytedance.feishu.cn/wiki/wikcnjtmsVlCDS553O1Pj261SHe')
      end

      # 统一工具链配置：慢函数、热修、覆盖率
      def setup_toolchain_unify
        is_exist = false
        return unless toolchain_config[:unify.to_s].include?($lark_env.xcode_version)

        # 查询是否有与版本匹配的工具链，如果没有就使用默认的
        app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
        bundle_id = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
        if exist_toolchains.include?(bundle_id)
          is_exist = true
          Logger.info('unify toolchain exists')
          return
        end

        download_path = download_toolchain(toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:url.to_s])
        if File.exist?(download_path)
          is_exist, = extract(download_path, true)
        else
          Logger.warn('unify toolchain download failed')
        end
      ensure
        if is_exist
          @@status[:toolchain][:coverage] = :exist
          @@status[:toolchain][:hotfix] = :exist
          @@status[:toolchain][:evil_method] = :exist
          @@status[:toolchain][:gmo] = :exist
          @@status[:toolchain][:frame_outlining] = :exist
        end
      end

      def setup_zip_ld
        zip_ld_url = toolchain_config[:zip_ld.to_s][:default.to_s]
        # 查询是否有与版本匹配的压缩链接器，没有就使用默认的
        if toolchain_config[:zip_ld.to_s].include?(current_app_version.to_s)
          zip_ld_url = toolchain_config[:zip_ld.to_s][current_app_version.to_s]
        end

        download_path = download_toolchain(zip_ld_url)

        if File.exist?(download_path)
          workspace_dir = current_workspace_dir
          system "rm -rf #{workspace_dir}/bin/ld;tar zxvf #{download_path} -C #{workspace_dir}/bin/"
          system "ls -l #{workspace_dir}/bin/ld"
          @@status[:toolchain][:zip_ld] = :exist
        else
          Logger.warn('zip ld download failed')
        end
      end

      def setup_custom_ld
        custom_ld_url = ''
        custom_ld_md5 = ''
        custom_ld_path = ''
        custom_ld_install_path = ''
        workspace_dir = podfile_dir
        user_home = File.expand_path('~')
        lark_toolchain_dir = "#{user_home}/.lark_toolchain"

        use_kunld = $lark_env.lark_kunld_enable && !Lark::Project::Utils.compatible_with_xcode15_and_above
        use_jild = ($lark_env.lark_kunld_enable && Lark::Project::Utils.compatible_with_xcode15_and_above) || $lark_env.lark_jild_enable

        if use_jild
          linker_version = toolchain_config[:lark_jild.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
          custom_ld_url = toolchain_config[:lark_jild.to_s][linker_version][:url.to_s]
          custom_ld_md5 = toolchain_config[:lark_jild.to_s][linker_version][:md5.to_s]
          custom_ld_install_path = "#{lark_toolchain_dir}/linker/jild/#{linker_version}"
          custom_ld_path = "#{custom_ld_install_path}/bin/ld"
          linker_type = :jild
        elsif use_kunld
          linker_version = toolchain_config[:lark_kunld.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
          custom_ld_url = toolchain_config[:lark_kunld.to_s][linker_version][:url.to_s]
          custom_ld_md5 = toolchain_config[:lark_kunld.to_s][linker_version][:md5.to_s]
          custom_ld_install_path = "#{lark_toolchain_dir}/linker/kunld/#{linker_version}"
          custom_ld_path = "#{custom_ld_install_path}/bin/kunld"
          linker_type = :kunld
        elsif $lark_env.lark_lld_enable
          linker_version = toolchain_config[:lark_lld.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
          custom_ld_url = toolchain_config[:lark_lld.to_s][linker_version][:url.to_s]
          custom_ld_md5 = toolchain_config[:lark_lld.to_s][linker_version][:md5.to_s]
          custom_ld_install_path = "#{lark_toolchain_dir}/linker/lld/#{linker_version}"
          custom_ld_path = "#{custom_ld_install_path}/ld64.lld"
          linker_type = :lld
        end

        if File.exist?(custom_ld_path) and Digest::MD5.file(custom_ld_path).hexdigest == custom_ld_md5
          Logger.info("custom ld #{File.expand_path(custom_ld_path)} exist, not update")
          if $lark_env.lark_lld_enable
            @@status[:toolchain][:lark_lld] = :exist
          elsif $lark_env.lark_kunld_enable
            @@status[:toolchain][:lark_kunld] = :exist
          elsif $lark_env.lark_jild_enable
            @@status[:toolchain][:lark_jild] = :exist
          end
          return
        end

        download_path = download_toolchain(custom_ld_url)

        if File.exist?(download_path)
          destination = File.dirname("#{custom_ld_install_path}")
          FileUtils.mkdir_p(destination) unless File.directory?(destination)
          system "rm -rf #{custom_ld_install_path};tar zxvf #{download_path} -C #{destination}"
          system "mv #{destination}/#{linker_type.to_s} #{destination}/#{linker_version}"
          if $lark_env.lark_lld_enable
            @@status[:toolchain][:lark_lld] = :exist
          elsif $lark_env.lark_kunld_enable
            @@status[:toolchain][:lark_kunld] = :exist
          elsif $lark_env.lark_jild_enable
            @@status[:toolchain][:lark_jild] = :exist
          end
        else
          Logger.warn('custom ld download failed')
        end
      end

      def setup_compiler_driver
        workspace_dir = current_workspace_dir
        custom_driver_url = toolchain_config[:lark_compiler_driver.to_s][:default.to_s][:url.to_s]
        custom_driver_md5 = toolchain_config[:lark_compiler_driver.to_s][:default.to_s][:md5.to_s]
        custom_driver_clang = "#{workspace_dir}/bin/lark_clang"
        custom_driver_swiftc = "#{workspace_dir}/bin/lark_swiftc"

        if File.exist?(custom_driver_clang) and Digest::MD5.file(custom_driver_clang).hexdigest == custom_driver_md5
          Logger.info("custom driver #{File.expand_path(custom_driver_clang)} exist, not update")
          if $lark_env.lark_compiler_driver_enable
            @@status[:toolchain][:lark_compiler_driver] = :exist
          end
          return
        end

        download_path = download_toolchain(custom_driver_url)

        if File.exist?(download_path)
          system "rm -rf #{custom_driver_clang};rm -rf #{custom_driver_swiftc};tar zxvf #{download_path} -C #{workspace_dir}/bin/"
          if $lark_env.lark_compiler_driver_enable
            @@status[:toolchain][:lark_compiler_driver] = :exist
          end
        else
          Logger.warn('custom driver download failed')
        end
      end

      def setup_gmo_summary
        tos_bucket = "toutiao.ios.arch"
        workflow_app_id = 137801
        arch = "arm64"
        build_channel = ENV.fetch("BUILD_CHANNEL", "inhouse")
        xcode_build_configuration = ENV.fetch("XCODE_BUILD_CONFIGURATION", "Release")
        gmo_summary_remote_keys = "Lark-#{xcode_build_configuration}-#{build_channel}-#{current_app_version.to_s}"
        dancecc_swift_version = EEScaffold::Swift.version.to_s
        tos_key="llvm-infrastructure-tools/gmo-summary/#{workflow_app_id}/swift-#{dancecc_swift_version}/#{arch}/#{gmo_summary_remote_keys}/merged.index"
        tos_url="https://voffline.byted.org/download/tos/schedule/#{tos_bucket}/#{tos_key}"
        Logger.info("download gmo index #{tos_url}")

        download_path = download_toolchain(tos_url)
        if File.exist?(download_path)
          workspace = ENV.fetch("WORKSPACE", File.join(File.dirname(__FILE__), '../../../../../..'))
          gmoindex_path = "#{workspace}/gmo-summary/merged.index"
          FileUtils.mkdir_p(File.dirname(gmoindex_path)) unless Dir.exist?(File.dirname(gmoindex_path))
          FileUtils.mv(download_path, gmoindex_path)
        else
          Logger.error('gmoindex download failed')
        end
      end
      
      def update_env_and_report
        if $lark_env.code_coverage_enable || $lark_env.hotpatch_enable
          if @@status[:toolchain][:coverage] == :not_exist or @@status[:toolchain][:hotfix] == :not_exist
            push_notification(:coverage_and_hotfix)
          end
          ENV['CODE_COVERAGE_ENABLE'] = 'false' if @@status[:toolchain][:coverage] == :not_exist
          ENV['HOTPATCH_ENABLE'] = 'false' if @@status[:toolchain][:hotfix] == :not_exist
        end

        if $lark_env.evil_method_enable && (@@status[:toolchain][:evil_method] == :not_exist)
          ENV['EVIL_METHOD_ENABLE_V2'] = 'false'
          push_notification(:evil_method)
        end

        if $lark_env.zip_text_ld_enable && (@@status[:toolchain][:zip_ld] == :not_exist)
          ENV['ZIP_TEXT_LD_ENABLE'] = 'false'
        end

        if $lark_env.frame_outlining_enable && (@@status[:toolchain][:frame_outlining] == :not_exist)
          ENV['LARK_FRAME_OUTLINING'] = 'false'
        end

        if ($lark_env.global_machine_outlining_summary_emit || $lark_env.global_machine_outlining_summary_consume) && (@@status[:toolchain][:gmo] == :not_exist)
          ENV['LARK_GMO_SUMMARY_EMIT'] = 'false'
          ENV['LARK_GMO_SUMMARY_CONSUME'] = 'false'
        end

        ENV['LARK_LLD_ENABLE'] = 'false' if $lark_env.lark_lld_enable && (@@status[:toolchain][:lark_lld] == :not_exist)

        ENV['LARK_KUNLD_ENABLE'] = 'false' if $lark_env.lark_kunld_enable && (@@status[:toolchain][:lark_kunld] == :not_exist)

        ENV['LARK_JILD_ENABLE'] = 'false' if $lark_env.lark_jild_enable && (@@status[:toolchain][:lark_jild] == :not_exist)
      end

      def push_notification(type)
        job_id = ENV['WORKFLOW_JOB_ID']
        bot_msg = "不存在xcode版本(#{$lark_env.xcode_version})对应#{type}的toolchain:https://bits.bytedance.net/bytebus/build/log?jobId=#{job_id}&appId=137801"
        Logger.warn(bot_msg)
        cmd = "python3 #{File.join(File.dirname(__FILE__),
                                   '../../../../../coverage/sentBotwithWarning.py')} --botMsg '#{bot_msg}'"
        Open3.capture3(cmd)
      end

      def pre_install_config(pod_target)
        pod_target_xcconfig = pod_target.root_spec.attributes_hash['pod_target_xcconfig']

        module_use_dancecc_toolchain = false
        # 代码覆盖率
        if $lark_env.code_coverage_enable && Lark::Project::ToolChainConfig.coverage_list.include?(pod_target.name)
          Logger.success("coverage applying #{pod_target.name}")
          consumed_modules.add(pod_target.name)
          pod_target_xcconfig['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -enable-bdcov -Xllvm -bdstakepass-level=2 -Xllvm -bdstakepass-output-dir=${PODS_TARGET_SRCROOT}/coverageIndex -Xllvm -bdstakepass-build-source-dir=${PODS_TARGET_SRCROOT} -Xllvm -bdstakepass-enable-log=1 -Xllvm -arch=arm64'
          module_use_dancecc_toolchain = true
        end

        # 二进制重排
        if $lark_env.binary_reorder_enable
          Logger.success("binary reorder stub applying #{pod_target.name}")
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          toolchain_bundle_id = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          toolchain_name = exist_toolchains[toolchain_bundle_id]
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_bundle_id
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += " -Onone -Xfrontend,-g -Xllvm -enable-bd-codestake=1 -Xllvm -bdcodestake-level=0 -Xllvm -bdcodestake-log-level=0 -Xllvm -bdcodestake-output-dir=#{$lark_env.bd_stake_output_dir}"
          pod_target_xcconfig['OTHER_CFLAGS'] = " -O0 -mllvm -enable-bd-codestake=1 -mllvm -bdcodestake-level=0 -mllvm -bdcodestake-log-level=0 -mllvm -bdcodestake-output-dir=#{$lark_env.bd_stake_output_dir}"
          module_use_dancecc_toolchain = true
        end

        # 慢函数
        if should_enable_evil_method(pod_target.name)
          Logger.success("evil method applying #{pod_target.name}")
          consumed_modules.add(pod_target.name)
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          toolchain_bundle_id = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          toolchain_name = exist_toolchains[toolchain_bundle_id]
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_bundle_id
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xllvm -enable-hmd-codestake=1 -Xllvm -hmdcodestake-output-dir=${DWARF_DSYM_FOLDER_PATH}/../HMDHangMapfile'
          pod_target_xcconfig['CC'] = "${HOME}/Library/Developer/Toolchains/#{toolchain_name}/usr/bin/clang"
          pod_target_xcconfig['CXX'] = "${HOME}/Library/Developer/Toolchains/#{toolchain_name}/usr/bin/clang"
          pod_target_xcconfig['SWIFT_COMPILATION_MODE'] = 'singlefile'
          module_use_dancecc_toolchain = true
        end

        # 热修复
        if $lark_env.hotpatch_enable && Lark::Project::ToolChainConfig.hotpatch_list.include?(pod_target.name)
          Logger.success("hotpatch applying #{pod_target.name}")
          consumed_modules.add(pod_target.name)
          pod_target_xcconfig['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -bdhotfix -save-temps'
          pod_target_xcconfig['GCC_OPTIMIZATION_LEVEL'] = 's'
          pod_target_xcconfig['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
          pod_target_xcconfig['SWIFT_COMPILATION_MODE'] = 'singlefile'
          pod_target_xcconfig['ENABLE_BITCODE'] = 'NO'
          module_use_dancecc_toolchain = true
        # 若single_module_llvm_emission打开，模块不是热修模块，才打开
        elsif $lark_env.enable_single_module_llvm_emission
            Logger.success("single module llvm emission applying #{pod_target.name}")
            pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xfrontend -enable-single-module-llvm-emission'
        end

        # Frame Outlining, 热修模块不支持Osize, 暂时不开启
        if $lark_env.frame_outlining_enable && Lark::Project::ToolChainConfig.frame_outlining_list.include?(pod_target.name) && !Lark::Project::ToolChainConfig.hotpatch_list.include?(pod_target.name)
          Logger.success("frame outlining applying #{pod_target.name}")
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          pod_target_xcconfig['OTHER_CFLAGS'] += ' -mllvm --homogeneous-prolog-epilog'
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xllvm --homogeneous-prolog-epilog'
          module_use_dancecc_toolchain = true
        end

        # Global Machine Outlining Summary Emit
        if $lark_env.global_machine_outlining_summary_emit
          Logger.success("gmo summary emit applying #{pod_target.name}")
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xllvm -enable-machine-outliner -Xllvm -emit-machine-outlining-summary -Xllvm -machine-outlining-summary-path -Xllvm $(SRCROOT)/gmo-base'
          module_use_dancecc_toolchain = true
        end

        # Global Machine Outlining Consume Consume
        if $lark_env.global_machine_outlining_summary_consume && global_machine_outlining_list.include?(pod_target.name)
          Logger.success("gmo summary consume applying #{pod_target.name}")
          app_version = toolchain_config[:unify.to_s][$lark_env.xcode_version].include?(current_app_version.to_s) ? current_app_version.to_s : :default.to_s
          pod_target_xcconfig['TOOLCHAINS'] = toolchain_config[:unify.to_s][$lark_env.xcode_version][app_version][:bundle_id.to_s]
          workspace = ENV.fetch("WORKSPACE", File.join(File.dirname(__FILE__), '../../../../../..'))
          gmo_path = "#{workspace}/gmo-summary/merged.index"
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += " -Xllvm -gmo-summary -Xllvm #{gmo_path}"
          module_use_dancecc_toolchain = true
        end        

        # 兼容开源工具链存在的bug
        if module_use_dancecc_toolchain && ["LarkSetting", "ByteViewDebug"].include?(pod_target.name)
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xfrontend -disable-availability-checking'
        end

        # 编译驱动, 非自定义工具链开启
        if $lark_env.lark_compiler_driver_enable && !consumed_modules.include?(pod_target.name)
          Logger.success("custom driver applying #{pod_target.name}")
          driver_modules.add(pod_target.name)
          pod_target_xcconfig['CC'] = '$(SRCROOT)/../bin/lark_clang'
          pod_target_xcconfig['SWIFT_EXEC'] = '$(SRCROOT)/../bin/lark_swiftc'
          pod_target_xcconfig['SWIFT_USE_INTEGRATED_DRIVER'] = 'NO'
        end
      end

      def post_install_config(pod_name, release_settings)
        # 这里因为工具链融合了，热修的配置比慢函数全，所以优先使用热修的配置
        if $lark_env.hotpatch_enable && ToolChainConfig.hotpatch_list.include?(pod_name)
          Logger.success("release optimization level changed for hotpatch: #{pod_name}")
          release_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
          release_settings['GCC_OPTIMIZATION_LEVEL'] = 's'
          release_settings['LLVM_LTO'] = 'NO'
        elsif should_enable_evil_method(pod_name)
          Logger.success("evilMethod_closeLTO_#{pod_name}")
          release_settings['LLVM_LTO'] = 'NO'
        end
      end

      def lldb_patch_config
        if @lark_lldb_config.nil?
          lark_lldb_config_url = 'http://tosv.byted.org/obj/ee-infra-ios/lark_lldb_patch.json'
          lark_lldb_config_url = ENV[:LARKLLDBCONFIG.to_s] unless ENV[:LARKLLDBCONFIG.to_s].nil?
          unless config_exist?(lark_lldb_config_url)
            Logger.error('lark lldb config not exist')
            return nil
          end
          data_hash = JSON.load(URI.open(lark_lldb_config_url))
          @lark_lldb_config = data_hash
        end

        @lark_lldb_config
      end

      def toolchain_config
        if @toolchain_config.nil?
          toolchain_config_url = 'http://tosv.byted.org/obj/ee-infra-ios/lark_toolchain_config_v3.json'
          toolchain_config_url = ENV[:LARKTOOLCHAINCONFIG.to_s] unless ENV[:LARKTOOLCHAINCONFIG.to_s].nil?
          unless config_exist?(toolchain_config_url)
            Logger.error('toolchain config not exist')
            return nil
          end
          data_hash = JSON.load(URI.open(toolchain_config_url))
          @toolchain_config = data_hash
        end

        @toolchain_config
      end

      def online_toolchain_setting
        if @online_toolchain_setting.nil?
          require 'toml'
          toolchain_setting_url = 'http://tosv.byted.org/obj/ee-infra-ios/lark_toolchain_setting.toml'
          unless config_exist?(toolchain_setting_url)
            Logger.error('online toolchain setting not exist, make it empty')
            # 不存在就置空
            @online_toolchain_setting = Hash.new 
            return @online_toolchain_setting
          end
          data_hash = URI.open(toolchain_setting_url) do |file|
            TOML.load(file.read)
          end          
          @online_toolchain_setting = data_hash
        end

        @online_toolchain_setting
      end

      def exist_toolchains
        if @exist_toolchains.nil?
          toolchains = {}
          if File.directory?(File.expand_path('~/Library/Developer/Toolchains'))
            Find.find(File.expand_path('~/Library/Developer/Toolchains')) do |path|
              next unless path.end_with?('xctoolchain') && File.exist?("#{path}/Info.plist")

              info_plist = ::Plist.parse_xml("#{path}/Info.plist")
              bundle_id = info_plist['CFBundleIdentifier']
              toolchains[bundle_id] = File.basename(path)
            end
          end
          @exist_toolchains = toolchains
        end
        @exist_toolchains
      end

      def exist_lldbs
        if @exist_lldbs.nil?
          lldbs = {}
          if File.directory?(File.expand_path('~/Library/Developer/Toolchains'))
            Find.find(File.expand_path('~/Library/Developer/Toolchains')) do |path|
              next unless path.end_with?('xctoolchain') && File.exist?("#{path}/Info.plist")

              info_plist = ::Plist.parse_xml("#{path}/Info.plist")
              bundle_id = info_plist['CFBundleIdentifier']
              display_name = info_plist['DisplayName']
              next unless display_name.include?('LLDB')
              lldbs[bundle_id] = path
            end
          end
          @exist_lldbs = lldbs
        end
        @exist_lldbs
      end


      def config_exist?(config)
        url = URI.parse(config)
        if url.scheme == 'http'
          req = Net::HTTP.new(url.host, url.port)
          res = req.request_head(url.path)
          res.code == '200'
        else
          File.exist?(url.path)
        end
      end

      def download_toolchain(url)
        Logger.info("Downloading toolchain: #{url}")
        uri = URI.parse(url)
        file_name = File.basename(uri.path)
        temp_dir = Dir.mktmpdir
        download_path = File.join(temp_dir, file_name)
        download = URI.open(url)
        IO.copy_stream(download, download_path)
        download_path
      end

      def extract(tar_gz_archive, is_normal = true)
        # 解压路径设置参见官网说明：https://github.com/apple/swift/blob/main/README.md#installing-into-xcode
        destination = File.expand_path('~')
        # 兼容非标准的情况，比如热修工具链生成的包是非标准的格式，与官方文档不同
        destination = File.expand_path('~/Library/Developer/Toolchains') unless is_normal
        FileUtils.mkdir_p(destination) unless File.directory?(destination)
        success = system("tar -xzf #{tar_gz_archive} -C #{destination}")
        extracted = ''
        if is_normal
          Gem::Package::TarReader.new(Zlib::GzipReader.open(tar_gz_archive)) do |tar|
            tar.each do |entry|
              if extracted.empty? and File.dirname(entry.full_name).end_with?('.xctoolchain')
                extracted = File.join(destination, File.dirname(entry.full_name))
                break
              end
            end
          end
        else
          Zip::File.open(tar_gz_archive) do |zip_file|
            zip_file.each do |entry|
              if extracted.empty? and (File.dirname(entry.name).end_with?('.xctoolchain') or File.dirname(entry.name).end_with?('.xctoolchain/'))
                extracted = File.join(destination, File.dirname(entry.name))
                break
              end
            end
          end
        end

        if success
          info_plist = ::Plist.parse_xml("#{extracted}/Info.plist")
          bundle_id = info_plist['CFBundleIdentifier']
          exist_toolchains[bundle_id] = File.basename(extracted)
        else
          Logger.error('extract toolchain failed')
        end

        [success, extracted]
      end

      def evil_method_config
        if @evil_method_config.nil?
          evil_method_config_url = 'http://tosv.byted.org/obj/ee-infra-ios/lark_evil_method_config.json'
          evil_method_config_url = ENV[:LARKEVILMETHODCONFIG.to_s] unless ENV[:LARKEVILMETHODCONFIG.to_s].nil?
          unless config_exist?(evil_method_config_url)
            Logger.error('evil method config not exist')
            return nil
          end
          data_hash = JSON.load(URI.open(evil_method_config_url))
          @evil_method_config = data_hash
        end

        @evil_method_config
      end

      def global_machine_outlining_list
        if @global_machine_outlining_list.nil?
          global_machine_outlining_list_url = 'http://tosv.byted.org/obj/ee-infra-ios/lark_global_machine_outlining_list'
          global_machine_outlining_list_url = ENV[:LARKGMOLISTCONFIG.to_s] unless ENV[:LARKGMOLISTCONFIG.to_s].nil?
          unless config_exist?(global_machine_outlining_list_url)
            Logger.error('gmo list config not exist')
            return nil
          end

          begin
            URI.open(global_machine_outlining_list_url) do |f|
              page_string = f.read
              @global_machine_outlining_list = page_string.split
            end
          rescue StandardError
            Logger.error('gmo list is unavaliable, check result may not be right')
          end
        end

        @global_machine_outlining_list
      end

      def hotpatch_list
        if @hotpatch_list.nil?
          hotpatch_list_url = 'http://tosv.byted.org/obj/ee-infra-ios/hotpatch_list'
          hotpatch_list_url = ENV[:LARKHOTPATCHLIST.to_s] unless ENV[:LARKHOTPATCHLIST.to_s].nil?
          unless config_exist?(hotpatch_list_url)
            Logger.error('hotpatch list not exist')
            return nil
          end

          begin
            URI.open(hotpatch_list_url) do |f|
              page_string = f.read
              @hotpatch_list = page_string.split
            end
          rescue StandardError
            Logger.error('hotpatch list is unavaliable, check result may not be right')
          end
        end

        @hotpatch_list
      end

      def consumed_modules
        @consumed_modules = Set.new if @consumed_modules.nil?
        @consumed_modules
      end

      def driver_modules
        @driver_modules = Set.new if @driver_modules.nil?
        @driver_modules
      end

      def current_app_version
        if @current_app_version.nil?
          # 没有版本的情况，置0
          @current_app_version = Pod::Version.new('0')
          workspace_dir = ENV['BIT_WORKSPACE_DIR']
          unless !workspace_dir.nil? && File.directory?(workspace_dir)
            workspace_dir = File.join(File.dirname(__FILE__), '../../../../../..')
          end

          info_plist = "#{workspace_dir}/Lark/Info.plist"
          if File.exist?(info_plist)
            info_plist = ::Plist.parse_xml(info_plist)
            short_version = info_plist['CFBundleShortVersionString']
            app_version = Pod::Version.new(short_version)
            @current_app_version = Pod::Version.new("#{app_version.major}.#{app_version.minor}")
            system "bit env set LARK_APP_VERSION #{@current_app_version}"
          end
        end

        @current_app_version
      end

      def current_workspace_dir
        workspace_dir = ENV['BIT_WORKSPACE_DIR']
        unless !workspace_dir.nil? && File.directory?(workspace_dir)
          workspace_dir = File.join(File.dirname(__FILE__), '../../../../../..')
        end
        workspace_dir
      end

      # 慢函数添加宏定义
      def config_evil_method(lark_proj)
        return unless $lark_env.evil_method_enable

        lark_proj.targets.each do |target|
          next unless target.name == 'Lark'

          target.build_configurations.each do |config|
            next unless config.name == 'Release'

            config.build_settings['OTHER_SWIFT_FLAGS'] ||= ''
            config.build_settings['OTHER_SWIFT_FLAGS'] += ' -D ENABLE_EVIL_METHOD'
          end
        end
      end

      def config_zip_text_ld(lark_proj)
        text_str = '-Wl,-rename_section,__TEXT,__cstring,__RODATA,__cstring,-rename_section,__TEXT,__objc_methname,__RODATA,__objc_methname,-rename_section,__TEXT,__objc_classname,__RODATA,__objc_classname,-rename_section,__TEXT,__objc_methtype,__RODATA,__objc_methtype,-rename_section,__TEXT,__gcc_except_tab,__RODATA,__gcc_except_tab,-rename_section,__TEXT,__const,__RODATA,__const,-rename_section,__TEXT,__text,__BD_TEXT,__text,-rename_section,__TEXT,__textcoal_nt,__BD_TEXT,__text,-rename_section,__TEXT,__StaticInit,__BD_TEXT,__text,-rename_section,__TEXT,__stubs,__BD_TEXT,__stubs,-segprot,__BD_TEXT,rx,rx,-rename_section,__TEXT,__u__selector,__CUSTOM_TEXT,__text,-segprot,__CUSTOM_TEXT,rx,rx'
        if $lark_env.zip_text_ld_enable
          lark_proj.targets.each do |target|
            next unless target.name == 'Lark'

            target.build_configurations.each do |config|
              next unless config.name == 'Release'

              other_lfflags = config.build_settings['OTHER_LDFLAGS']
              if config.build_settings['OTHER_LDFLAGS'].include?(text_str) && (other_lfflags.is_a? Array)
                config.build_settings['OTHER_LDFLAGS'].delete(text_str)
              end
              config.build_settings['OTHER_LDFLAGS'] << ' -Wl,-rename_section,__TEXT,__text,__BD_TEXT,__text,-rename_section,__TEXT,__textcoal_nt,__BD_TEXT,__text,-rename_section,__TEXT,__StaticInit,__BD_TEXT,__text,-rename_section,__TEXT,__stubs,__BD_TEXT,__stubs,-segprot,__BD_TEXT,rx,rx,-rename_section,__TEXT,__u__selector,__CUSTOM_TEXT,__text,-segprot,__CUSTOM_TEXT,rx,rx'
              config.build_settings['OTHER_LDFLAGS'] << ' -fuse-ld=$(SRCROOT)/bin/ld/ld'
              config.build_settings['OTHER_LDFLAGS'] << ' -Wl,-compress=lzfse'
              config.build_settings['OTHER_LDFLAGS'] << ' -Wl,-icf_safe' if $lark_env.outline_ld_enable
              # GMO后bloutofrange问题合并原子
              config.build_settings['OTHER_LDFLAGS'] << ' -Wl,-optimize_aliasing_islands' if $lark_env.global_machine_outlining_summary_consume
              lark_proj.save
              Logger.info("当前OTHER_LDFLAGS:\n#{config.build_settings['OTHER_LDFLAGS']}")
            end
          end
        end

        if $lark_env.text_rename_close
          lark_proj.targets.each do |target|
            next unless target.name == 'Lark'

            target.build_configurations.each do |config|
              next unless config.name == 'Release'

              other_lfflags = config.build_settings['OTHER_LDFLAGS']
              if config.build_settings['OTHER_LDFLAGS'].include?(text_str) && (other_lfflags.is_a? Array)
                config.build_settings['OTHER_LDFLAGS'].delete(text_str)
                lark_proj.save
              end
              Logger.info("当前OTHER_LDFLAGS:\n#{config.build_settings['OTHER_LDFLAGS']}")
            end
          end
        end
      end

      def config_lark_custom_ld(xcconfig, target_name, config)
        # 如果压缩链接器启用，所有自定义ld均不启用
        if $lark_env.zip_text_ld_enable && target_name == "Pods-Lark" && config == "Release"
          Logger.info("当前#{target_name}压缩链接器开启，自定义链接器不启用")
          return
        end

        user_home = File.expand_path('~')
        lark_toolchain_dir = "#{user_home}/.lark_toolchain"
        custom_ld_config = ''
        lld_version = toolchain_config[:lark_lld.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
        lld_config = "-fuse-ld=#{lark_toolchain_dir}/linker/lld/#{lld_version}/ld64.lld"
        kunld_version = toolchain_config[:lark_kunld.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
        kunld_config = "-fuse-ld=#{lark_toolchain_dir}/linker/kunld/#{kunld_version}/bin/kunld -Wl,-random_uuid"
        # 如果>Xcode15-beta1, kunld和jild合并, 这里为什么是linker参数，因为cocoapods会转成-l"d-classic", 虽然目前没影响但是还是保险点别让当库处理了
        jild_version = toolchain_config[:lark_jild.to_s].include?(Utils.current_xcode_version) ? Utils.current_xcode_version : :default.to_s
        kunld_config = "-fuse-ld=#{lark_toolchain_dir}/linker/jild/#{jild_version}/bin/ld -Wl,-random_uuid,-ld_classic" if Lark::Project::Utils.compatible_with_xcode15_and_above 
        jild_config =  "-fuse-ld=#{lark_toolchain_dir}/linker/jild/#{jild_version}/bin/ld -Wl,-random_uuid"
        ld_classic_config = '-ld_classic'

        if $lark_env.lark_lld_enable
          custom_ld_config = lld_config
        elsif $lark_env.lark_kunld_enable
          custom_ld_config = kunld_config
        elsif $lark_env.lark_jild_enable
          custom_ld_config = jild_config
        elsif Lark::Project::Utils.compatible_with_xcode15_and_above # 如果>Xcode15-beta1, 且未设置链接器，使用ld_classic
          custom_ld_config = ld_classic_config
        end
        unless custom_ld_config.empty?
          # 加个空格规避拼接问题
          if xcconfig['OTHER_LDFLAGS'] != nil
            xcconfig['OTHER_LDFLAGS'] += " #{custom_ld_config}"
          else
            xcconfig['OTHER_LDFLAGS'] = " #{custom_ld_config}"
          end
        end
      end

      # 慢函数是否开启 https://bytedance.feishu.cn/wiki/wikcnuK1LJEdmOOsg6nVF4Bvprh
      def should_enable_evil_method(pod_name)
        evil_method_enable = false
        return evil_method_enable unless $lark_env.evil_method_enable
        return evil_method_enable if evil_method_config.nil?

        # 命中黑名单，直接跳过
        if evil_method_config[:black_list.to_s].include?(pod_name)
          # 格式必定包含start_version
          start_version = evil_method_config[:black_list.to_s][pod_name][:start_version.to_s]
          if Pod::Version.new(start_version) <= current_app_version
            if evil_method_config[:black_list.to_s][pod_name].include?(:end_version.to_s)
              end_version = evil_method_config[:black_list.to_s][pod_name][:end_version.to_s]
              return evil_method_enable if current_app_version <= Pod::Version.new(end_version)
            else
              return evil_method_enable
            end
          end
        end

        evil_method_enable = true if evil_method_config[:default_white_list.to_s].include?(pod_name)

        evil_method_enable
      end

      # 恢复LLDB Toolchain sourcekit的修复(疑似bug)
      def revoke_lldb_patch
        dancecc_toolchain_path = Lark::Project::Utils.dancecc_toolchain_path
        return if !File.exist?(dancecc_toolchain_path)

        broken_lldb_patch = [
          "usr/lib/sourcekitd.framework",
          "usr/lib/libswiftDemangle.dylib"
        ]

        broken_lldb_patch.each do |path|
          dancecc_path = File.join(dancecc_toolchain_path, path)
          if File.symlink?(dancecc_path)
            Logger.info("revoke lldb patch: #{dancecc_path}")
            File.unlink(dancecc_path)
          end
        end

        lib_dir = File.join(dancecc_toolchain_path, "usr/lib")
        if File.exist?(lib_dir) && !File.symlink?(lib_dir) && Dir.empty?(lib_dir)
          Logger.info("remove lib：#{lib_dir}")
          FileUtils.rm_rf(lib_dir)
        end
      end
      
      # 修复LLDB Toolchain 功能(profiling、playground)
      def patch_lldb_toolchain
        # get online config
        unless lldb_patch_config.include?(Lark::Project::Utils.current_xcode_version)
          Logger.info("当前Xcode#{Lark::Project::Utils.current_xcode_version}不支持lldb toolchain 自动修复")
          return
        end
        lldb_patch = lldb_patch_config[Lark::Project::Utils.current_xcode_version]
        xcode_toolchain_path = Lark::Project::Utils.current_xcode_toolchain_path
        dancecc_toolchain_path = Lark::Project::Utils.dancecc_toolchain_path
        return if !File.exist?(dancecc_toolchain_path) or !File.exist?(xcode_toolchain_path)

        # check local is exist and patch
        lldb_patch.each do |source, destination|
          # get path
          xcode_path = File.join(xcode_toolchain_path, source)
          dancecc_path = File.join(dancecc_toolchain_path, destination)
          # check file is exist
          if !File.symlink?(dancecc_path)
            Logger.info("patch lldb toolchain #{dancecc_path} -> #{xcode_path}")
            FileUtils.mkdir_p(File.dirname(dancecc_path)) unless Dir.exist?(File.dirname(dancecc_path))
            File.symlink(xcode_path, dancecc_path)
          elsif !File.exist?(dancecc_path) || (File.realpath(xcode_path) != File.realpath(dancecc_path))
            Logger.info("update lldb toolchain #{dancecc_path} -> #{xcode_path}")
            File.unlink(dancecc_path)
            File.symlink(xcode_path, dancecc_path)
          end
        end
      end

      def add_toolchain_tips(tip)
        @@lark_toolchain_tips << tip 
      end

      # 注入LLDBInitFile文件
      def update_lldb_init_file(defined_in_file)
        project_lldbinit_path = File.join(File.dirname(defined_in_file), "LLDBInitFile")
        FileUtils.touch(project_lldbinit_path) unless File.exist?(project_lldbinit_path)

        inject_line = <<~LOADDEFAULTCONFIG	
        script import os,lldb; lldb_global_path = os.path.join(os.path.expanduser('~'), '.lldbinit'); lldb.debugger.HandleCommand(f'command source {lldb_global_path}') if os.path.exists(lldb_global_path) else print("~/.lldbinit not found")      
        LOADDEFAULTCONFIG

        # 检查是否已经注入
        lldbinit_injected = false
        File.foreach(project_lldbinit_path).with_index do |line, _line_number|
          if line.start_with?(inject_line.strip)
            lldbinit_injected = true
            next
          end
        end
        
        # 注入到第一行
        unless lldbinit_injected
          Logger.success "Inject load default lldbinit into project LLDBInitFile"

          tips = <<~TIPS	
          script print(" * * * * * * * * * * ")
          script print(" For LLDB Speed Up: https://bytedance.feishu.cn/wiki/wikcnjtmsVlCDS553O1Pj261SHe ")
          script print(" * * * * * * * * * * ")
          TIPS

          new_contents = ""
          File.open(project_lldbinit_path, 'r') do |fd|
            contents = fd.read
            new_contents =  "#{inject_line}#{tips}#{contents}"
          end
          File.open(project_lldbinit_path, 'w') do |fd| 
            fd.write(new_contents)
          end
        end
      end
    end

    class Logger
      @@log_stack = []
      class << self
        def success(s, record = true)
          puts "[LarkToolChain] #{s}".green
          @@log_stack << s.green if record
        end

        def info(s, record = true)
          puts "[LarkToolChain] #{s}"
          @@log_stack << s if record
        end

        def warn(s, record = true)
          puts "[LarkToolChain] #{s}".yellow
          @@log_stack << s.yellow if record
        end

        def error(s, record = true)
          puts "[LarkToolChain] #{s}".red
          @@log_stack << s.red if record
        end

        def debug(s, record = true)
          debug_mode = ENV['LARK_TOOLCHAIN_DEBUG'].to_s == 'true' || ENV['LARK_TOOLCHAIN_DEBUG'].to_i == 1
          if debug_mode
            puts "[LarkToolChain] -DEBUG- #{s}"
            @@log_stack << s if record
          end
        end
      end
    end

    # 用于存放toolchain关联的配置：生效的模块、模块的配置
    class ToolChainConfig
      class << self
        def coverage_list
          %w[
          ]
        end

        # extension pod 不插桩
        def offline_coverage_for_bid
          %w[
            LarkShareExtension
            LarkExtensionCommon
            ByteViewBoardcastExtension
            ByteRtcScreenCapturer
            LarkNotificationServiceExtension
            LarkNotificationServiceExtensionLib
            LarkExtensionServices
            LarkLocalizations
            LarkWidget
          ]
        end

        def hotpatch_list
          return ToolChainManager.instance.hotpatch_list unless ENV[:LARKHOTPATCHLIST.to_s].nil?

          %w[
            ByteWebImage
            LarkMessageCore
            ByteViewTab
            LarkWorkplace
            MailSDK
            LarkNavigation
            CCMMod
            Calendar
            LarkFeed
            LarkSafeMode
            LarkAccount
            LarkAccountInterface
            LarkEnv
            TTMicroApp
            EEMicroAppSDK
            OPGadget
            LarkAppStateSDK
            LarkMicroApp
            LarkTabMicroApp
            OPSDK
            EcosystemWeb
            WebBrowser
            LarkWebViewContainer
            WorkplaceMod
            LarkOpenPlatform
            LarkOpenPlatformAssembly
            LarkAppLinkSDK
            OPFoundation
            ECOInfra
            LarkOPInterface
            Blockit
            OPBlock
            OPBlockInterface
            LarkWebviewNativeComponent
            OPPlugin
            OPPluginBiz
            OPPluginManagerAdapter
            LarkOpenPluginManager
            LarkOpenAPIModel
            JsSDK
            LarkMessageCard
            NewLarkDynamic
            LarkLynxKit
            LarkStorage
            AnimatedTabBar
            LarkNavigation
            LarkTab
            LarkSplash
            LarkPerf
            LarkPerfBase
            LarkDowngrade
            BootManager
            LarkPreload
            LarkPreloadDependency
            LarkDowngradeDependency
            BootManagerDependency
            BootManagerConfig
            LarkMonitor
          ]
        end

        def frame_outlining_list
          %w[
            LarkChat
          ]
        end

        def global_machine_outlining_list
          ToolChainManager.instance.global_machine_outlining_list
        end

        def evil_method_list
          ToolChainManager.instance.evil_method_config[:default_white_list.to_s]
        end
      end
    end
  end
end




module Pod
  class Target
    class BuildSettings
      alias merged_xcconfigs_1226 merged_xcconfigs
      def merged_xcconfigs(xcconfig_values_by_consumer_by_key, attribute, overriding: {})
        xcconfig = merged_xcconfigs_1226(xcconfig_values_by_consumer_by_key, attribute, overriding: overriding)
        # 有些pod会引入CC配置污染，这里统一设置一次
        if $lark_env.lark_compiler_driver_enable
          if xcconfig.key?(:CC.to_s) and xcconfig[:CC.to_s].include?('$(SRCROOT)/../bin/lark_clang')
            xcconfig[:CC.to_s] = '$(SRCROOT)/../bin/lark_clang'
          end

          if xcconfig.key?(:SWIFT_EXEC.to_s) and xcconfig[:SWIFT_EXEC.to_s].include?('$(SRCROOT)/../bin/lark_swiftc')
            xcconfig[:SWIFT_EXEC.to_s] = '$(SRCROOT)/../bin/lark_swiftc'
          end
        end
        # 强制统一二三方库的无效配置，目前二方的BDWebImage和一些三方库还没适配
        if $lark_env.build_for_all_arch
          xcconfig.delete("EXCLUDED_ARCHS[sdk=iphonesimulator*]")
        else
          xcconfig['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        end
        xcconfig
      end
    end
  end
end

module Pod
  class Podfile
    module DSL
      # 灰度功能
      def is_toolchain_feature_active(enable, percent)
        # 不符合条件
        return unless enable

        require 'macaddr'
        require 'mac_address'

        # 不在灰度范围内(大于14.3默认打开)
        if !(Pod::Version.new(Lark::Project::Utils.current_xcode_version) >= Pod::Version.new('14.3')) && (MacAddress.new(Lark::Project::LarkMacAddr.fake_address).to_i % 100 > percent)
          return
        end

        if block_given?
          yield
        else
          raise '[LarkGray] needs an gray action!'
        end
      end
    end
  end
end

module Lark
  module Project
    class LarkMacAddr
      class << self
        def ensure_valid_encoding(text)
          text = text.dup
          if text.encoding == Encoding::BINARY
            text.force_encoding('UTF-8')
          end # binary always valid, so use internal utf8 instead
          return text if text.valid_encoding?

          if (locale = Encoding.find('locale')) && locale != text.encoding && text.force_encoding(locale).valid_encoding?
            return text
          end

          # utf-8 and locale both invalid, try third encoding check gem
          require 'rchardet'
          return text if text.force_encoding(CharDet.detect(text)['encoding']).valid_encoding?

          # can't guess the right encoding, this is unlikely enter, replace invalid bytes
          text.encode!('UTF-8', 'UTF-8', invalid: :replace)
        end

        def fake_address
          return @mac_address if defined? @mac_address and @mac_address

          @mac_address = MacAddr.from_getifaddrs
          return @mac_address if @mac_address

          cmds = '/sbin/ifconfig', '/bin/ifconfig', 'ifconfig', 'ipconfig /all', 'cat /sys/class/net/*/address'

          output = nil
          cmds.each do |cmd|
            command = Mixlib::ShellOut.new(cmd)
            begin
              command.run_command
            rescue StandardError
              next
            end
            stdout = command.stdout
            next unless stdout and stdout.size > 0

            output = stdout and break
          end
          raise "all of #{cmds.join ' '} failed" unless output

          output = ensure_valid_encoding output
          @mac_address = parse(output)
        end
    end
    end
  end
end

module Pod
  module UserInterface
    class << self
      alias print_warnings_0404 print_warnings
      def print_warnings
        info = warnings.select { |warning| warning[:message].include?('Lark Toolchain') }
        info.each do |warning|
          warnings.delete(warning)
          warnings.push(warning)
        end
        print_warnings_0404
      end
    end
  end
end
