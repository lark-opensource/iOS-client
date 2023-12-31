
# frozen_string_literal: true

autoload :Versionomy, 'versionomy'

require 'yaml'
require 'cocoapods'
# 这是Podfile的入口require文件，所以这里require "lark/project"
require 'lark/project'
require_relative 'integration/pod/patch'
require_relative 'toolchain_manager'
require 'fileutils'
require 'xcodeproj'
require_relative '../../../../../../.orbit_enable_user.rb'

# 推荐使用这个缩写来获取环境相关配置
$lark_env = Lark::Project::Environment.instance

module Pod
  # 存放Podfile扩展方法，
  # lark平台特化的方法和配置，需要以lark_前缀开头
  # 相关的配置主要以lark为模版，且子工程也可能用到。但要注意子工程环境裁剪的影响
  class Podfile
    # 这些模版和配置可直接调用，也可以参考复制为模版手动调用
    # 模版相对配置内聚度更粗，只有一个模糊的执行时机, 更可能需要删改.
    # rubocop:disable Metrics/MethodLength

    def lark_seer_optimize_enable
      # 开关选项可以参考
      # CocoaPods Optimize说明： https://bytedance.feishu.cn/wiki/wikcnnyWLo5FIcxhn3lxQmEzPE9#3VJZ9w
      # Lark Pod优化实践： https://bytedance.feishu.cn/wiki/wikcnhGtRqk3HQqVqa0inrIp0cg?from=from_lark_index_search
      # ENV['COCOAPODS_CACHE_VERSIONS'] ||= 'true'
      ENV['COCOAPODS_AUTO_UPDATE_REPO'] ||= 'true'
      ENV['COCOAPODS_REMOVE_PODFILE_CHECKSUM'] ||= 'true'
      ENV['COCOAPODS_ADD_CACHE_SUPPORT'] ||= 'true'
      ENV['COCOAPODS_CACHE_SANDBOX_ANALYZER'] ||= 'true'
      # ENV['COCOAPODS_LINK_POD_CACHE'] ||= 'true'

      # 下载提速
      ENV['COCOAPODS_CONVERT_GIT_TO_HTTP'] ||= 'true'
      ENV['COCOAPODS_PARALLEL_PODS_CACHE'] ||= 'true'
      ENV['COCOAPODS_SKIP_CLEAN_POD_CACHES'] ||= 'true'
    end

    def force_orbit!
      if $lark_env.local? && ENV['ORBIT_EXECUTABLE_PATH'].nil? && (ENV["FORCE_LOCAL"] || "") != "true"
        raise "
        ❌❌❌当前用户在 orbit 试用名单内，请使用 orbit 调用命令，比如：orbit pod install;
        Orbit 安装命令: `/bin/bash -c \"$(curl -fsSL http://tosv.byted.org/obj/ee-infra-ios/tools/Orbit/install.sh)\"`
        相关文档: https://bytedance.feishu.cn/wiki/UnG8wzhbZiWhRZkkCfLcTuzGnJh

        如果已经使用了orbit请使用`orbit update`获取最新版本，[抱拳][抱拳][抱拳]
        如果有问题，可以联系孔凯凯（kongkaikai@bytedance.com） or 苏鹏（supeng.charlie@bytedance.com）
        "
      end
    end

    def force_xcode_lint!
      if $lark_env.local? and (ENV["FORCE_LOCAL"] || "") != "true"
        raise "Xcode version lint 失败，请检查日志" unless system("which -s orbit && orbit lint xcode version -s 15.0.0 -l 15.0.1")
      end
    end

    def try_to_install_orbit
      return unless ($lark_env.local? and (ENV["FORCE_LOCAL"] || "") != "true")
      if system("which orbit > /dev/null 2>&1")
        current_orbit_version = `orbit --version`.strip.split(" ")[0]
        if Versionomy.parse(current_orbit_version) < Versionomy.parse("0.0.55-alpha")
          puts '自动升级 orbit'
          `orbit update`
        else
          puts "Orbit version: #{current_orbit_version}"
        end
      else
        puts "Try to install orbit..."
        `/bin/bash -c "$(curl -H 'Cache-Control: no-cache' -fsSL http://tosv.byted.org/obj/ee-infra-ios/tools/Orbit/install.sh)"`
      end
    end

    # 通用的一些基础配置
    # @option hummer_tags [Hash], hummer的自定义tags, value只支持bool值
    def lark_template_common_setup(hummer_tags: nil, **_opt)
      try_to_install_orbit
      force_orbit!
      force_xcode_lint!
      raise '❌❌❌ 请不要直接执行pod XXXX,命令前面加上bundle exec在执行' if ENV['BUNDLE_BIN_PATH'].nil?

      $pod_ui_filter = proc do |message|
        message.include? "uses the unencrypted 'http' protocol to transfer the Pod." or
          message.start_with? 'Unable to read the license file'
      end

      # plugin 'cocoapods-amicable'
      lark_seer_optimize_enable
      plugin 'EEScaffold'

      ENV['COCOAPODS_SHARED_CACHE'] ||= 'true'
      # 默认不上传，主仓会上传材料
      # ENV['COCOAPODS_SHARED_CACHE_UPLOAD'] ||= 'true'
      if ENV['COCOAPODS_SHARED_CACHE'] == 'true'
        require 'cocoapods/downloader/sharedcache'
        Pod::Downloader::Sharedcache.server = Pod::Downloader::Sharedcache::Server::EESC.new
        if hummer_tags
          hummer_tags['SharedCache'] = true
          hummer_tags['SharedCacheUpload'] = ENV['COCOAPODS_SHARED_CACHE_UPLOAD'] == 'true'
        end
        lark_report_pod_shared_cache_patch
      else
        hummer_tags["SharedCache"] = false if hummer_tags # rubocop:disable all
      end

      hummer_tags['STRIP_RUST_BITCODE'] = true if hummer_tags && (v = ENV['STRIP_RUST_BITCODE']) && !v.empty?

      platform :ios, $lark_env.deployment_target_ios
      inhibit_all_warnings!
      use_frameworks! :linkage => :static

      incremental_installation = $lark_env.local? ? !((ENV["REMOTE_CACHE_CHANGED"] || "") == "true") : false      
      puts "incremental installation: #{incremental_installation}"

      install!('cocoapods',
               incremental_installation: incremental_installation,
               generate_multiple_pod_projects: true,
               warn_for_multiple_pod_sources: false,
               warn_for_unused_master_specs_repo: false)

      lark_migrate_pod_mirror
      lark_use_common_pod_sources!
      lark_set_hummer_tags(hummer_tags) if hummer_tags

      # 压缩编译参数长度
      use_short_link!
      disable_framework_header_search_paths! except: [
        'JSONModel', # need by TTMicroApp
        'TTMicroApp', # need by EEMicroAppSDK
        'CJComponents',
        'CJPay',
        'CJPayDebugTools',
        'SAMKeychain',
        'Lynx'
      ]

      # 使用M1原生模拟器，如果想强行切回Rosetta，请参考 https://bytedance.feishu.cn/wiki/AEizwKNrSiIzblkHNE1cu5dDnWh
      lark_build_for_all_arch!

      # 自定义工具链安装
      Lark::Project::ToolChainManager.instance.setup_toolchain(self) unless ENV['IS_CUSTOM_AFTER_PIPLINE'] == 'true'

      # patch to error duplicate
      $verify_no_duplicates_uuid = true
      require_relative "integration/xcodeproj/patch"
    end

    # @param installer [Pod::Installer]
    def lark_template_common_pre_install(installer)
      # lint: if generate multiple scoped pod_target, downstream pod don't know choose which
      # 先关掉，可以适当放松，只有间接依赖不确定使用哪一个时会有问题
      # lark_check_duplicate_pod_targets installer
      lark_check_configuration_dependency installer
      if $lark_env.check_arch_deps? and rules = $lark_env.check_arch_rules
        lark_check_arch_dependency(
          # FIXME: 这个依赖关系因为切App环境和各种条件编译参数可能不全，容易漏，暂时依赖于对应环境的打包检测
          # 另外因为依赖和Pods不全，生成的架构图其实也不全..
          PodGroup::View.graph_from_specs(installer.analysis_result.specifications),
          pod_group_manager.repository,
          rules
        )
      end

      # modify build_settings in pre_install, so cache check will be valid
      lark_use_common_pod_target_config installer
      lark_create_common_module_map_for_static_library(installer)
      fix_swift_include_config(installer)
      lark_use_common_aggregate_target_config installer
    end

    # @param installer [Pod::Installer]
    # @param warn_as_error [nil, #include?, :all, Hash]
    #   Hash: { "Debug" => #include? }
    #   #include?: a list of pod need to enable warn as error
    #   :all  all set warn as error
    #   nil, false: ignored
    def lark_template_common_post_install(installer, **opt)
      # the post installer change won't mark cache invalid, and the results is not full(unless use clean install)
      # but it can set config by configurations.., or do last patch
      lark_fix_lynx_header installer

      lark_use_common_post_settings_patch installer, **opt

      lark_patch_assert_method installer if $lark_env.has_assert_patch?

      inject_eesc_lldb

      if $lark_env.remote_cache_enable
        `mkdir -p .rc && touch .rc/.remote_cache_mark` 
      else
        File.delete ".rc/.remote_cache_mark" if File.exists? ".rc/.remote_cache_mark"
      end
    end

    ######### common config

    def defer_actions
      @defer_actions ||= []
    end

    # 一些需要延后到Podfile推出前执行的action, 在Podfile退出前调用这个方法
    # @return [void]
    def flush_defer_actions!
      defer_actions.each(&:call)
      @defer_actions = nil
    end

    # 直接source通用的pod_sources
    def lark_use_common_pod_sources!
      $lark_env.pod_sources.each { |s| source s }
    end

    # 去除构建架构限制，二进制切换为xcframework
    def lark_build_for_all_arch!()
      # ci暂时不启用
      if $lark_env.ci? && !$lark_env.is_binary_cache_job
        puts "build for all arch is not avaliable in ci temporaly"
        return
      end
      puts "[LarkToolChain] All build arch enabled, Usage:https://bytedance.feishu.cn/wiki/AEizwKNrSiIzblkHNE1cu5dDnWh".green
      ENV['BUILD_FOR_ALL_ARCH'] = 'true'
      Lark::Project::ToolChainManager.instance.add_toolchain_tips("M1原生模拟器的配置已开启,如果想切回Rosetta运行, 请参考：https://bytedance.feishu.cn/wiki/AEizwKNrSiIzblkHNE1cu5dDnWh".green)
    end

    # 对于开启LTO的组件，在本地编译/CI编译验证使用它的非LTO版本规避二次编译、提升链接速度
    def local_use_module_nolto!
      ENV['LARK_USE_MODULE_NOLTO'] = 'true' if $lark_env.local?
    end

    # patch dancecc lldb, fix playground、sourcekit、profiling
    def lark_patch_lldb!
      ENV['LARK_PATCH_DANCECC_LLDB'] = 'true' if $lark_env.local?
      Lark::Project::ToolChainManager.instance.add_toolchain_tips("lldb工具链playground、profiling功能修复, 请参考：https://bytedance.feishu.cn/docx/OYfXd5Ie5oK9JFxy6I4cW8Frnic".green)
    end

    @@rust_sdk_local_podspecs = {}
    # 开启本地源码调试 rust-sdk
    def rust_sdk_local_dev!(path: '../rust-sdk', proj_name: 'Lark')
      rust_sdk_root_dir = Pathname.new(path)
      if rust_sdk_root_dir.relative?
        base = Pathname.new(Dir.pwd)
        rust_sdk_root_dir = base.join(rust_sdk_root_dir)
      end

      rust_sdk_podspec_dir = rust_sdk_root_dir.join('molten/lark-bindings/rust-sdk/swift/')
      raise 'rust-sdk path is invalid: no such directory ' + rust_sdk_podspec_dir.to_s unless rust_sdk_podspec_dir.exist?

      # Update `rust-sdk` reference path if custom
      project = Xcodeproj::Project.open(proj_name + '.xcodeproj')
      group_reference = project.objects_by_uuid.values.find { |obj| obj.isa == 'PBXFileReference' && obj.name == 'rust-sdk' }

      if group_reference
        if path != group_reference.path
          puts '📁 配置本地 rust-sdk 自定义路径 => ' + "#{rust_sdk_root_dir}"
          group_reference.set_source_tree('<absolute>')
          group_reference.set_path(rust_sdk_root_dir)
        end
      else
        puts '📁 添加本地 rust-sdk 自定义路径 => ' + "#{rust_sdk_root_dir}"
        group_reference = project.main_group.new_file(rust_sdk_root_dir)
        group_reference.name = 'rust-sdk'
        group_reference.set_source_tree('<absolute>')
      end
      
      project.save 

      ENV['RUST_SDK_LOCAL_DEV'] = 'true' # Use this VAR to enable lldb_install_rust_formatter feature

      @@rust_sdk_local_podspecs['RustPB'] = rust_sdk_podspec_dir.join('RustPB.podspec').to_s
      @@rust_sdk_local_podspecs['RustSDK'] = rust_sdk_podspec_dir.join('RustSDK.podspec').to_s

      pod 'RustSDK/LocalDev'
      pod 'RustPB/LocalDev'

      puts '🦀️ 开启本地 rust-sdk 源码调试 => ' + "#{@@rust_sdk_local_podspecs}"
      %x(NOT_IN_BITS_ENV=true bash "#{rust_sdk_root_dir.join('molten/.script/setup_env.sh')}")
      puts '🦀 Rust toolchain: ' + %x(cd #{rust_sdk_root_dir} && rustup target add aarch64-apple-ios aarch64-apple-ios-sim && rustup show active-toolchain)

      puts '🚀 初始化本地 RustPB 代码 ...'
      %x(bash "#{rust_sdk_podspec_dir.join('gen_rustpb.sh')}")

      %x(mkdir -p "#{rust_sdk_podspec_dir.join('libraries')}")
      %x(touch "#{rust_sdk_podspec_dir.join('libraries').join('liblark.a')}")
    end

    # lark环境内通用二进制配置
    # @param strategy:
    #   :all 开启全部二进制(默认)
    #   :pb 只有PB开启二进制
    #   other 手动开启二进制
    # @param binary_repo default use common binary cache. can specify custom repo
    # @yieldself [Pod::PodfilePatch] additional config
    def lark_use_common_binary_config(strategy: :all, binary_repo: nil, &block)
      # rubocop:disable all
      return unless $lark_env.can_change_module_stability

      ENV['EESC_ONLY_BINARY_REPO'] ||= '1'
      unless binary_repo
        local_swift_version = EEScaffold::Swift.version
        should_show_xcode_version_warning = true

        binary_repo = if $lark_env.available?('swift', '5.3.2') and $lark_env.unavailable?('swift', '5.7')
                        "git@code.byted.org:lark/binary_v#{local_swift_version.to_s.delete!(".")}.git"
                      else
                        local_swift_build = EEScaffold::Swift.build.to_s

                        if $lark_env.support_binary_swift_version.include?(local_swift_build)
                          repo_version = local_swift_build.gsub('.', '_')

                          should_show_xcode_version_warning = false if repo_version
                          "git@code.byted.org:lark/xcbinary_v#{repo_version}.git" if repo_version
                        end
                      end

        should_show_xcode_version_warning = true if local_swift_version <= Versionomy.parse('5.7')

        if should_show_xcode_version_warning
          notice = "
          - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = -

            你的swift版本是 #{local_swift_version} (#{local_swift_build})
            当前已经不再(或者还未)发布新的二进制缓存，当前适用的Xcode版本为:

              - Xcode 15.0 (飞书 7.4 及之后版本提供二进制)
              - Xcode 14.3(.1) (飞书 6.1 ~ 7.4 版本提供二进制)
              - Xcode 14.2 (飞书 5.29 ~ 7.4 版本提供二进制)
              - Xcode 14.1 (飞书 5.25 ~ 7.4 版本提供二进制)
              - Xcode 14.0(.1) (飞书 5.22 ~ 5.32 版本提供二进制)
              - 飞书代码到支持 & 推荐的Xcode版本映射表

              | 飞书代码版本 | 推荐 Xcode 版本 | 支持的 Xcode 版本 |
              | - | - | - |
              | >= 7.5.0        | Xcode 15.0 | Xcode 15.0 ~ 15.1 beta    |
              | 6.1.0 ~ 7.4.0   | Xcode 14.1 | Xcode 14.1 ~ Xcode 14.3.1 |
              | 5.32.0 ~ 7.4.0  | Xcode 14.1 | Xcode 14.1 ~ Xcode 14.2.0 |
              | 5.22.0 ~ 5.32.0 | Xcode 14.0 | Xcode 14.0 ~ Xcode 14.2.0 |
              | 4.10.0 ~ 5.22.0 | Xcode 13.0 | Xcode 13.0 ~ Xcode 13.4.1 |
              | < 4.10.0        | Xcode 12.5 | Xcode 12.5                |

            更新Xcode后请按照文档说明刷新本地缓存避免二进制版本混用引入错误:
            https://bytedance.feishu.cn/docx/doxcnwhrTrD1T0c6BCJQ1GYF3cd

          - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = -
          "
          Lark::UI.notice notice # 执行到时候打印
          UI.warn notice # 执行结束打印
        end

        unless binary_repo
          Lark::UI.notice "你的swift版本是 #{local_swift_version} (#{local_swift_build}), 与当前部分二进制版本不兼容，已经自动切换为源码"
          return
        end
      end

      podfile = self
      patch do
        use_binary_repo binary_repo
        if strategy == :pb || ENV['ONLY_PB_USES_BINARY'] == 'true'
          %w[RustPB ServerPB SwiftProtobuf].each { |name| binary name }
        elsif strategy == :all
          binary_all!
        end

        # 这里是为了将某个库标记为使用源码和上面不同的是可以开启接口稳定
        [
          # 这里插入 'NAME' 可以将某个库单独切换成源码，需要重新执行 `pod install`
          'BootManagerConfig', # 方便看配置
          'TTMacroManager',
          'TTMLeaksFinder', # Debug 宏
          'LKCommonsLogging', # 宏，条件编译，for log
          'LarkBaseService', # 宏，条件编译，for log
          'LarkRustClient', # debug assert
          'HTTProtocol', # debug assert
          'MLeaksFinder', # 宏，条件编译，for memory leak
          'LarkSQLCipher', # 已经是二进制了
          'RustSDK', # 已经是二进制了
          'oc-opus-codec', # 已经是二进制了
          'UniverseDesignTag', # UniverseDesignTag 切换到源码避免低版本死锁
          'LarkAssertConfig'
        ].each { |v| source v }

        [].each { |v| source v, :unstable }

        variants = podfile.lark_binary_variants
        variants&.each do |name, tag|
          name = Specification.root_name(name)
          use_binary_variant name, tag
        end

        # unless ENV['CACHE_BINARY'] == '1'
        #   # 发布二进制但默认用源码的库
        #   %w[].each { |v| source v }
        # end

        # can further config
        instance_exec(self, &block) if block
      end
    end

    # @param installer [Pod::Installer]
    def lark_create_common_module_map_for_static_library(installer)
      # TODO: 先临时处理这两个，全量的module转化需要进一步测试
      force_module = $lark_env.force_enable_module_names
      static_library_by_module = installer.pod_targets.map { |pod_target|
        next if pod_target.should_build?
        next unless pub = pod_target.public_header_mappings_by_file_accessor
        next unless pub.values.any? { |v| !v.empty? }
        next unless force_module.include? pod_target.pod_name

        # 如果自己有module map的，应该优先考虑手写的module map, 直接复制到对应的路径里使用
        if module_map = pod_target.file_accessors.first.module_map and module_map.exist?
          pod_target.force_static_module_map_file_to_link = module_map.expand_path
          next
        end

        [pod_target, pub]
      }.compact
      return if static_library_by_module.empty?

      # build module tree {path => subtree { _header_, other subpath }}
      root = {}
      static_library_by_module.each do |_pt, pub|
        pub.each do |_acc, mapping|
          next if mapping.empty?
          mapping.each do |path, headers|
            components = path.to_s.split('/')
            node = components.reduce(root) do |node, c|
              node[c] ||= {}
            end
            # 可能包含子文件夹和文件
            # 可能有多个重复的path(比如不同subspec)
            node['_headers_'] ||= Set.new
            node['_headers_'].merge(headers)
          end
        end
      end

      # build modulemap file
      buffer = []
      visit = proc do |name, value, d, path|
        buffer << "#{d}module #{name} {"
        subd = d + '  '
        if headers = value.delete('_headers_')
          headers.each do |v|
            buffer << %(#{subd}header "#{path}/#{File.basename(v)}")
          end
        end
        value.each { |k, v| visit[k, v, subd, [path, k].join('/')] }
        buffer << "#{subd}export *"
        buffer << "#{d}}"
      end
      root.each { |k, v| visit[k, v, '', k] }

      buffer = buffer.join("\n")
      module_path = installer.sandbox.public_headers.root + 'module.modulemap'
      module_path.dirname.mkpath
      File.write(module_path, buffer) unless module_path.exist? and File.read(module_path) == buffer

      # add include path to swift
      static_library_by_module = static_library_by_module.map(&:first).to_set
      installer.pod_targets.each do |pt|
        next unless pt.recursive_dependent_targets.any? { |v| static_library_by_module.include? v }

        xcconfig = pt.root_spec.attributes_hash['pod_target_xcconfig']
        xcconfig['SWIFT_INCLUDE_PATHS'] += ' ${PODS_ROOT}/Headers/Public'
        xcconfig['OTHER_CFLAGS'] += ' -fmodule-map-file=${PODS_ROOT}/Headers/Public/module.modulemap'
      end
    end

    def fix_swift_include_config(installer)
      installer.pod_targets.each do |pt|
        keys = pt.recursive_dependent_targets.map(&:name) & $lark_env.append_swift_include_module.keys
        # DEBUG LOG puts "KKK #{pt.recursive_dependent_targets} #{$lark_env.append_swift_include_module.keys} #{keys}"

        keys.each do |key|
          pt.root_spec.attributes_hash['pod_target_xcconfig']['SWIFT_INCLUDE_PATHS'] += (' ' + $lark_env.append_swift_include_module[key])
        end
      end
    end

    def pod_target_common_config(config)
      # 这些常用flag给予默认值，让后面不用判断和设置默认值
      config['WARNING_CFLAGS'] ||= +''
      config['OTHER_SWIFT_FLAGS'] ||= +''
      config['OTHER_CFLAGS'] ||= +''
      config['OTHER_LDFLAGS'] ||= +''
      config['GCC_PREPROCESSOR_DEFINITIONS'] ||= +''
      config['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] ||= +'$(inherited)'

      config['SWIFT_INCLUDE_PATHS'] ||= +''
      config['SWIFT_VERSION'] = '5.5'

      # 关闭 mac_catalyst 支持
      config['SUPPORTS_MACCATALYST'] = "NO"

      # 关闭自动生成资源文件对应的符号
      config['ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS'] = 'NO'

      config['IPHONEOS_DEPLOYMENT_TARGET'] = $lark_env.deployment_target_ios
      config['XROS_DEPLOYMENT_TARGET'] = $lark_env.deployment_target_visionos

      if $lark_env.observe_compilation_time
        config['OTHER_SWIFT_FLAGS'] ||= '$(inherited)'
        config['OTHER_SWIFT_FLAGS'] += ' -Xfrontend -warn-long-function-bodies=300 -Xfrontend -warn-long-expression-type-checking=100 -Xfrontend -debug-time-function-bodies -driver-time-compilation'
      end
    end

    # @param installer [Pod::Installer]
    def lark_use_common_pod_target_config(installer)
      dynamic_framework_pods = $lark_env.dynamic_framework_pods.to_set
      installer.pod_targets.each do |pod_target|
        lark_fix_unexpected_ldflags(pod_target)
        # rubocop:disable Layout/LineLength
        # 配置来源有：pod_target，shared config，app. 高层级可以选择提供默认值，合并，或者覆盖
        # 这里是shared config的配置
        attributes_hash = pod_target.root_spec.attributes_hash
        pod_target_xcconfig = (attributes_hash['pod_target_xcconfig'] ||= {}) # 保证存在, 使用方可以不用判断默认值了

        if dynamic_framework_pods.include? pod_target.pod_name
          pod_target.instance_variable_set(:@build_type, BuildType.dynamic_framework)
          pod_target_xcconfig['PODS_USE_DYNAMIC_FRAMWORK'] = 'YES'
          pod_target_xcconfig['DEBUG_INFORMATION_FORMAT'] = "dwarf" if $lark_env.remote_cache_enable
        end
        # 针对三方动态库修改buildSetting
        if $lark_env.dynamic_framework_third_pods.include? pod_target.pod_name
          pod_target_xcconfig['SWIFT_OPTIMIZATION_LEVEL'] = '-Osize'
          pod_target_xcconfig['GCC_OPTIMIZATION_LEVEL'] = 'z'
          pod_target_xcconfig['DEAD_CODE_STRIPPING'] = 'YES'
          pod_target_xcconfig['DEPLOYMENT_POSTPROCESSING'] = 'YES'
          pod_target_xcconfig['STRIP_INSTALLED_PRODUCT'] = 'YES'
          pod_target_xcconfig['STRIP_STYLE'] = 'all'
          pod_target_xcconfig['STRIPFLAGS'] = '-u'
          pod_target_xcconfig['GCC_SYMBOLS_PRIVATE_EXTERN'] = 'YES'
          pod_target_xcconfig['DEBUG_INFORMATION_FORMAT'] = "dwarf" if $lark_env.remote_cache_enable
        end

        pod_target_common_config pod_target_xcconfig

        pod_target_xcconfig['WARNING_CFLAGS'] += ' -Wno-nullability-completeness -Wno-nonnull -Wno-incomplete-umbrella'
        pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xcc -Wno-nullability-completeness -Xcc -Wno-nonnull -Xcc -Wno-incomplete-umbrella'
        pod_target_xcconfig['BUILD_LIBRARY_FOR_DISTRIBUTION'] = "YES" if $lark_env.remote_cache_enable

        # 关闭动态库TBD的自动生成，防止源码切换为二进制的时候，TargetArch/符号改变造成TBD无法自动生成导致的链接错误 https://bytedance.feishu.cn/wiki/F9ibwC1f4iU0vgkCkeKchqrCnQd
        pod_target_xcconfig['GENERATE_INTERMEDIATE_TEXT_BASED_STUBS'] = "NO"

        # Fix module_name 与 type 一致问题 https://forums.swift.org/t/pitch-fully-qualified-name-syntax/28482/87
        pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xfrontend -module-interface-preserve-types-as-written'
        pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -no-verify-emitted-module-interface' # 禁用 public swift interface 校验

        lark_check_pod_target(pod_target)
        # 添加KA宏 用于在SaaS包去除相关KA代码
        if $lark_env.is_ka
          pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' IS_KA=1'
          pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' IS_KA'
        end
        if $lark_env.is_oversea
          pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' OVERSEA'
        end

        # libwep 中定义了一个名为 ALPHA 的枚举值，会与宏中的ALPHA冲突，所以 libwebp 不追加该定义
        if $lark_env.testable && pod_target.name != "libwebp"
          pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' ALPHA=1'
          pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' ALPHA'
        end
        unless $lark_env.testable
          pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' LARK_NO_DEBUG=1'
          pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' LARK_NO_DEBUG'
        end
        # 资源条件编译参数注入
        pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' USE_BASE_IMP'
        pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' USE_DYNAMIC_RESOURCE'

        # 对objc库的header依赖和修复
        if headers = header_search_paths_for_pod(pod_target,
                                                 by_config: $lark_env.additional_header_include_config[pod_target.pod_name],
                                                 pod_targets_by_name: installer.pod_targets_by_name)
          pod_target_xcconfig['SYSTEM_HEADER_SEARCH_PATHS'] = headers.join(' ')
        end
        if $lark_env.allow_nonmodular_includes_target.include? pod_target.pod_name
          pod_target_xcconfig['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
          # CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES 只对objc生效，swift需要额外参数禁掉error
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xcc -Wno-error=non-modular-include-in-framework-module'
        end

        if $lark_env.tobsdk_flags_target.include? pod_target.pod_name
          pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' TOBSDK=1'
        end

        if $lark_env.mail_target.include? pod_target.pod_name
          if (ENV["REMOTE_CACHE_ENABLE"] || 'false') == 'true'
            pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' PROJECT_DIR=\""Dummy"\"'
          else
            pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' PROJECT_DIR=\""$PROJECT_DIR\/"\"'
          end
        end

        if pod_target.name == "LarkContainer"
          # 集成前的容器使用需要等待，避免返回nil强解崩溃
          pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' WAIT_REGISTER'
        end

        # this can break swift header dep on non-modular C header
        unless $lark_env.swift_objc_header_enable_target.include? pod_target.pod_name
          pod_target_xcconfig['SWIFT_INSTALL_OBJC_HEADER'] = 'NO'
        end
        # rubocop:enable Layout/LineLength

        pod_target_xcconfig['CODE_SIGN_IDENTITY'] = '' if pod_target.build_as_static?
        pod_target_xcconfig['EXPANDED_CODE_SIGN_IDENTITY'] = ''
        pod_target_xcconfig['CODE_SIGNING_REQUIRED'] = 'NO'
        pod_target_xcconfig['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end

    def lark_use_common_aggregate_target_config(installer)
      # @param [Pod::AggregateTarget]
      installer.aggregate_targets.each do |aggregate_target|
        aggregate_target.each_build_setting do |_config_name, bs|
          xcconfig = bs.custom_xcconfig
          xcconfig['CUSTOM_VERSION'] ||= +'1'

          pod_target_common_config xcconfig

          # 自定义链接器配置
          Lark::Project::ToolChainManager.instance.config_lark_custom_ld(xcconfig, aggregate_target.name, _config_name)

          xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' ALPHA' if $lark_env.testable
          xcconfig['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
          # CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES 只对objc生效，swift需要额外参数禁掉error
          xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xcc -Wno-error=non-modular-include-in-framework-module'
        end
      end
    end

    # some common setting
    # @param installer [Pod::Installer]
    # @param warn_as_error [nil, #include?, :all, Hash] inhibit_warnings_target will excludes
    #   Hash: { "Debug" => #include? }
    #   #include?: a list of pod need to enable warn as error
    #   :all  all set warn as error
    #   nil, false: ignored
    def lark_use_common_post_settings_patch(installer, warn_as_error: nil, **_opt)
      installer.generated_projects.each do |project|
        # 删除所有Target的自有配置
        project.targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
            config.build_settings.delete 'XROS_DEPLOYMENT_TARGET'
            config.build_settings.delete 'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'

            if warn_as_error
              config.build_settings.delete 'SWIFT_TREAT_WARNINGS_AS_ERRORS'
              config.build_settings.delete 'GCC_TREAT_WARNINGS_AS_ERRORS'
            end
          end
        end

        # 将自定义配置写入 Project
        project.build_configurations.each do |config|
          # Fix project warnings generated by POD in Xcode14
          config.build_settings['DEAD_CODE_STRIPPING'] = "YES"

          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $lark_env.deployment_target_ios
          config.build_settings['XROS_DEPLOYMENT_TARGET'] = $lark_env.deployment_target_visionos

          # Fix warning:  Double-quoted include 'xxxx.h'
          config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'

          if config.name.capitalize == "Debug"
            config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
          else
            config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
          end
          # CI多数情况下wholemodule编译更快(因为无缓存)
          config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule' if $lark_env.ci?

          if warn_as_error and installer.pod_targets_by_name[project.project_name]&.none?(&:inhibit_warnings?)

            should_warn_as_error = case warn_as_error
                                   when Hash then warn_as_error[config.name]&.include? project.project_name
                                   when :all then true
                                   when proc { |v| v.respond_to? :include? }
                                     warn_as_error.include? project.project_name
                                   end
            if should_warn_as_error
              config.build_settings['SWIFT_TREAT_WARNINGS_AS_ERRORS'] = 'YES'
              config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'YES'
            end
          end

        end
      end
    end

    # @param tags [Hash] 根据[文档](https://bytedance.feishu.cn/wiki/wikcnAbDdAubY9sCyyxHyQa0iyd#G3NwJo),
    #   value都会被转换为bool值, 代码会做转换保证格式正确
    def lark_set_hummer_tags(tags)
      return if tags.empty?

      workspace_path = ENV['WORKSPACE_PATH'] || Dir[defined_in_file.join('../*.xcworkspace')].first
      # mbox可能拿不到workspace，以后集成mbox再来调
      unless workspace_path && Dir.exist?(workspace_path)
        Lark::UI.notice('workspace_path not set, hummer tags set is ignored')
        return
      end
      set_script = File.expand_path('set_hummer_tags.py', __dir__)
      cmd = ['python3', set_script].concat(
        tags.transform_values { |v| Lark::Misc.true?(v) ? '1' : '0' }.flatten.map(&:to_s)
      )
      system({ 'WORKSPACE_PATH' => workspace_path }, *cmd) or raise "failed #{cmd}"
    end

    # @param pod_targets [Array<PodTarget>]
    # @return [Hash{Symbol => Specification}]
    def spec_types(pod_targets)
      pod_targets.map(&:root_spec).uniq.group_by do |s|
        if s.eesc_binary?
          :binary
        elsif Config.instance.sandbox.development_pods.include? s.name
          :local
        elsif s.version.to_s.include? 'binary'
          :bits_binary
        else
          :source
        end
      end
    end

    # @param pod_target [Pod::PodTarget]
    def lark_check_pod_target(pod_target)
      name = pod_target.pod_name
      if $lark_env.is_oversea
        if $lark_env.internal_only_list.include? name
          Lark::UI.multiline_notice <<-EOF
        "#{name}" 只应该被国内包依赖，不应该出现在海外包中。
        "#{name}" should not be installed because it is only allowed to be used in demestic package.
          EOF
          exit(1)
        end
      elsif $lark_env.international_only_list.include? name
        Lark::UI.multiline_notice <<-EOF
        "#{name}" 只应该被海外包依赖，不应该出现在国内中。
        "#{name}" should not be installed because it is only allowed to be used in international package.
        EOF

        exit(1)
      end
    end

    # lint: 如果同一pod生成多个target, 使用方会不知道应该链接依赖哪一个。所以先禁掉保证一致
    # @param installer [Installer]
    def lark_check_duplicate_pod_targets(installer)
      duplicate_pod_targets = installer.pod_targets_by_name.values.select { |a| a.length > 1 }
      duplicate_pod_targets.each do |a|
        Pod::UI.warn 'Duplicate Pod target with different subspecs, defined in:'
        a.each do |pod_target|
          Pod::UI.warn "  - #{pod_target.name}(#{pod_target.specs.map(&:name).join(', ')}) contained in: #{
            pod_target.target_definitions.map(&:name).join(', ')
          }"
        end
      end
      raise 'Currently Not Support Duplicate Pod Targets' unless duplicate_pod_targets.empty?
    end

    # https://github.com/CocoaPods/CocoaPods/pull/9149
    # https://github.com/CocoaPods/CocoaPods/issues/9658
    # podspec中使用configuration dependency的依赖，并不会影响到主app，依赖会无视条件引入。
    # 主app中是否根据configuration集成配置，只看pod的configuration，而且也不会处理递归依赖的情况..
    # 这一块容易引入意外赖，先禁止掉，使用subspec的方式实现可选依赖..
    # @param installer [Installer]
    def lark_check_configuration_dependency(installer)
      # @param pt [Pod::PodTarget]
      specs_with_config_dep = installer.pod_targets
                                       .flat_map(&:library_specs)
                                       .group_by { |s| s.root.name }
                                       .map do |root_name, specs|
        # @param s [Pod::Specification]
        has_config_dep = specs.any? { |s| v = s.attributes_hash['configuration_pod_whitelist'] and !v.empty? }
        root_name if has_config_dep
      end.compact
      unless specs_with_config_dep.empty?
        Pod::UI.warn "spec with configuration dependency, may import unexpected deps. list is: \n\t[#{specs_with_config_dep.join(', ')}]" # rubocop:disable all
        Pod::UI.warn 'please use optional subspec to dep on conditional pods'
      end
    end

    @@git_root_dir = (`git rev-parse --show-toplevel`.presence || `git rev-parse --show-superproject-working-tree`).strip

    def local_podspec(name)
      return nil if $lark_env.ignore_local_pod_names.include?(name)
      @podspec_map ||=
        begin
          map = {}

          base = Pathname.new(@@git_root_dir)
          config_path = base.join(".bits/bits_components.yaml").to_s

          if File.exist? config_path
            YAML.load_file(config_path).to_hash['components_publish_config'].to_hash
                .map { |key, value| map[key] = base.join(value.to_hash["archive_podspec_file"]).to_s }
          else
            subdir = %w[Modules Libs Bizs].join('|')
            ignores = %w[*/Pods/ */temp/ */cocoapods/ external].map { |item| " -not -path '#{item}'" }.join(' ')

            `find #{@@git_root_dir} #{ignores} -type f -name "*.podspec" | grep -E "#{@@git_root_dir}/(#{subdir})"`
              .strip.split("\n").each { |item| map[item.split("/")[-1].split(".")[0]] = item.strip }
          end

          map.merge!(@@rust_sdk_local_podspecs)

          map
        end

      @podspec_map[name]
    end

    def pod(name, *requirements)
      requirements = replace_with_local(name, requirements)
      super name, *requirements
    end

    # @param graph [Molinillo::DependencyGraph] 依赖图, payload应该有name属性, 对应每个subspec的name
    # @param groups [Hash<String, Hash>] name => group info
    # @param rules [Hash, nil] custom rules for arch
    def lark_check_arch_dependency(graph, groups, rules = nil)
      config = PodGroup::Check::Config.new(rules)
      checker = PodGroup::Check::Checker.new(graph: graph, groups: groups, config: config, ui: PodGroup::UI)
      success = checker.run!
      unless success
        msg = checker.diags.map { |v| v[1] == 'error' and v[0] }.compact
        raise "arch check failed! error message is:\n#{msg.join("\n")}"
      end
    end

    # rubocop:enable Metrics/MethodLength

    # 部分pod把自己的vendor产物也加入到了libraries和
    # @param pod_target [PodTarget]
    def lark_fix_unexpected_ldflags(pod_target)
      root_spec = pod_target.root_spec
      remove_vendor = lambda do |attr, get_names|
        remove = lambda do |hash|
          return unless hash
          values = hash[attr]
          if values
            values = [values] unless values.is_a? Array
            hash[attr] = values - get_names.call
          end
        end
        remove.call root_spec.attributes_hash
        root_spec.available_platforms.each do |plat|
          remove.call root_spec.attributes_hash[plat.to_sym.to_s]
        end
      end

      fas = pod_target.file_accessors.reject { |fa| fa.spec.non_library_specification? }
      vendored_libraries = fas.flat_map(&:vendored_libraries)
      unless vendored_libraries.empty?
        names = nil
        get_names = proc {
          names ||= vendored_libraries.map { |l| File.basename(l, File.extname(l)).delete_prefix('lib') }
        }
        remove_vendor.call('libraries', get_names)
      end
      # 暂时没有framework的非法数据，先不做处理
      # vendored_frameworks = fas.flat_map { |fa| fa.vendored_frameworks }
      # unless vendored_frameworks.empty?
      #   names = nil
      #   get_names = proc {
      #     names ||= vendored_frameworks.map { |f| File.basename(f, ".*") }
      #   }
      #   remove_vendor.call("frameworks", get_names)
      #   remove_vendor.call("weak_frameworks", get_names)
      # end
    end

    # lynx 生成了一些错误的header引用，做一些额外的兼容性patch
    # @param installer [Installer]
    def lark_fix_lynx_header(installer)
      lynx_umbrella_path = installer.sandbox.target_support_files_dir('Lynx').join('Lynx-umbrella.h')
      return unless lynx_umbrella_path.exist?

      contents = File.read(lynx_umbrella_path)
      has_replace = contents.gsub!('#import "../iOS/Lynx/LynxView.h"', '')
      return unless has_replace

      require 'active_support/core_ext/file/atomic'
      File.atomic_write(lynx_umbrella_path) { |f| f.write contents }
    end

    # patch assert method, so won't break app running
    # @param installer [Installer]
    def lark_patch_assert_method(installer)
      assert_template_path = Pathname(__dir__).join("assert_template.swift")
      copied = nil
      assert_store_path = lambda do
        copied ||= (installer.sandbox.target_support_files_root + "__assert_patch.swift").tap do |path|
          FileUtils.copy_file(assert_template_path, path)
        end
      end
      installer.target_installation_results.pod_target_installation_results.each do |name, result|
        next unless target = result.target and target.should_build?
        next unless target.uses_swift?
        project = result.native_target.project
        next unless project.is_a? Pod::Project
        UI.message "- Generating assert patch reference for #{target.pod_name}" do
          pod_name = target.pod_name
          dir = target.support_files_dir
          support_files_group = project.pod_support_files_group(pod_name, dir)
          file_reference = support_files_group.new_file(assert_store_path[])

          result.native_target.source_build_phase.add_file_reference(file_reference)
        end
      end
    end

    ######### Extension Helper Method

    # TODO: fix nonmodule header directly(even should fix frameworks header)，
    # not fix by hack search path and non modular include
    # @param by_config [Array, true, nil]
    #   true: auto search all recursive_dependent_targets search paths, this may cause search path will long
    #   Array: a list of dep pods headers search path
    # @return [Array, nil] header search paths
    def header_search_paths_for_pod(pod_target, by_config: nil, pod_targets_by_name: nil)
      return unless (config = by_config) and pod_targets_by_name

      # use true to represent all dependency
      included_targets = case config
                         when true then pod_target.recursive_dependent_targets
                         when Array
                           pod_targets_by_name.values_at(*config).compact.flatten(1)
                         else
                           raise 'unsupported'
                         end
      return nil if included_targets.empty?

      # 1.9 BuildSettings 按config区分，先兼容一下
      pt_build_settings = lambda do |pod_target|
        pod_target.build_settings[:release] || pod_target.build_settings[:debug]
      end

      headers = []
      # @param pt [Pod::PodTarget]
      included_targets.each do |pt|
        if pt.requires_frameworks? && pt.should_build?
          headers.push pt_build_settings[pt].framework_header_search_path
        else
          # the above code use direct include header, not <module/header.h>
          headers.push '${PODS_ROOT}/Headers/Public'
          headers.push "${PODS_ROOT}/Headers/Public/#{pt.pod_name}"
          # append vendored frameworks header
          headers.concat(pt_build_settings[pt].file_accessors.flat_map(&:vendored_frameworks).
            select { |f| f.extname == ".framework" }.
            map { |f|
              File.join '${PODS_ROOT}', f.relative_path_from(pt.sandbox.root), 'Headers'
            })

          # append xcframeworks header
          if $lark_env.available?('pod', '1.10') and pt_build_settings[pt].vendored_xcframeworks.is_a?(Array)
            headers.concat(pt_build_settings[pt].vendored_xcframeworks.map { |xcf|
              File.join "#{Target::BuildSettings.xcframework_intermediate_dir(xcf)}/#{xcf.name}.framework", 'Headers'
            })
          end
        end
      end
      headers.uniq
    end

    def inject_eesc_lldb
      return if ENV['JOB_NAME'] || ENV['CI_JOB_NAME']

      system <<~SHELL
        if test -e ~/.cocoapods/eesc_lldb.py && fgrep -e 'command script import ~/.cocoapods/eesc_lldb.py' ~/.lldbinit; then
          echo "already injected"
        else
          echo "inject eesc_lldb.py"
          echo "command script import ~/.cocoapods/eesc_lldb.py" >> ~/.lldbinit
        fi
        echo "参考文档：https://bytedance.feishu.cn/wiki/wikcnMfjHD7qIgWlvYNbW6P8pxe"
      SHELL
    end

    # copy master repo to pod_master_fork
    # this ensure master fork exist
    # TODO: future may switch to stable cdn
    def lark_migrate_pod_mirror
      mirror_dir = Pathname('~/.cocoapods/repos/byted-pod_master_fork').expand_path
      return if mirror_dir.exist?

      master_dir = mirror_dir.parent.join('master')
      return unless master_dir.exist?

      system <<~SH
        cd ~/.cocoapods/repos

        echo 'migrate pod master mirror. need about 1 minute'
        mkdir /tmp/byted-pod_master_fork
        # move .git first, then checkout, this way is double faster than cp entire dir. though still need 1 minute
        cp -af master/.git /tmp/byted-pod_master_fork && mv /tmp/byted-pod_master_fork .
        cd byted-pod_master_fork
        git remote set-url origin git@code.byted.org:lark/pod_master_fork.git
        git reset --hard @
        echo 'migrate pod master mirror end. '
      SH
    end

    # merge local and base variants from binary_expire.lock
    # local prior to base
    def lark_binary_variants
      base_variants_path = File.expand_path('binary_expire.lock', __dir__)
      local_variants_path = File.expand_path('../binary_expire.lock', defined_in_file)
      if ENV['MBOX_CURRENT_CONTAINER'] == 'iOS-client' && !File.exist?(local_variants_path) && mbox_container_path = ENV['MBOX_CURRENT_CONTAINER_PATH']
        local_variants_path = File.expand_path('binary_expire.lock', mbox_container_path)
      end
      [base_variants_path, local_variants_path].map do |path|
        JSON.parse(File.read(path)) if File.exist?(path)
      end.compact.reduce(:merge!)
    end

    def save_binary_list(installer, path)
      binary_list = spec_types installer.pod_targets
      binary_list_json = binary_list.to_json
      binary_list_dir = File.expand_path('Pods', path)
      binary_list_dir_path = File.expand_path('Pods/binary_component_list.json', path)
      puts '二进制失效列表临时路径：'
      puts binary_list_dir_path
      FileUtils.mkdir_p binary_list_dir
      File.open(binary_list_dir_path, 'w') { |file| file.write(binary_list_json) }
    end

    # lto module version make function, when release, version double shot
    # @param installer [Installer]
    def lto_module_version(version, type, is_release = true)
      lto_version = version
      case type
      when :rtcsdk
        segments = version.split('.').map(&:to_i)
        segments[-1] += 100
        candidate_nolto_version = segments.join('.')
      when :nfdsdk
        version_suffix = '.nolto'
        candidate_nolto_version = lto_version + version_suffix
      else
        throw 'lto module type not found'
      end

      nolto_version = if is_release
                        candidate_nolto_version
                      else
                        lto_version
                      end
      [lto_version, nolto_version]
    end

    # 私有helper方法放下面

    private

    # 用于将版本依赖替换成本地依赖，如果本地依赖存在；
    # 默认关闭非本地依赖的警告，除非显示声明；
    def replace_with_local(name, requirements)
      if $lark_env.switch_to_local_pod_enable
        podspec_path = local_podspec(name.split("/")[0])
        if podspec_path
          project_root_dir = `dirname #{defined_in_file}`.strip
          relative_pod_spec_dir = Pathname.new(podspec_path).relative_path_from(Pathname.new(project_root_dir)).dirname.to_s
          options = requirements.last.is_a?(Hash) ? requirements.pop : {}
          options[:path] = relative_pod_spec_dir
          options[:inhibit_warnings] = false unless options.include? :inhibit_warnings
          requirements = []
          requirements.append options
        end
      end
      requirements
    end

    # 用于计算shared_pod_cache的命中率 use / total_download
    def lark_report_pod_shared_cache_patch
      return unless Lark::Misc.require?('seer-hummer-trace-tools')

      sharedcache = Pod::Downloader::Sharedcache
      flush_recorded_requests = sharedcache::Patch.method(:flush_recorded_requests)
      sharedcache::Patch.define_singleton_method(:flush_recorded_requests) do |*args|
        time = Time.now
        if v = @recorded_shared_cache_pod and !v.empty?
          # 个别的predownload可能不被记录到download_count里.., 但也会正常使用共享缓存..
          Seer::HumrTrace.custom_stage_dt('pod_shared_cache_use_spec_count', v.size)
        end
        if download = @recorded_requests and !download.empty?
          Seer::HumrTrace.custom_stage_dt('pod_shared_cache_miss_spec_count', download.size)
          should_upload_count = download.count do |_name, record|
            record.download_size.nil? or (v = record.unused_size and v >= sharedcache.unused_threshold)
          end
          if should_upload_count > 0
            Seer::HumrTrace.custom_stage_dt('pod_shared_cache_upload_spec_count', should_upload_count)
          end
        end

        flush_recorded_requests.call(*args)
        Seer::HumrTrace.custom_stage_dt('pod_shared_cache_flush_time2', (Time.now - time) * 1000)
      end
    end
  end

  class Installer
    # @return [Hash<PodTarget>]
    def pod_targets_by_name
      # this assume pod_targets only set once.
      # if change pod_targets, also should clean this cache
      @pod_targets_by_name ||= pod_targets&.group_by(&:pod_name)
    end

    # 主要的app target对应的aggregate target, 默认第一个。可显示的覆盖
    def main_aggregate_target
      @main_aggregate_target ||= aggregate_targets.first
    end

    attr_writer :main_aggregate_target

    # https://bytedance.feishu.cn/wiki/wikcns3AltyuwiLOGLi9zZBPdie
    # 自定义hummer埋点，可以在kibana平台查看数据
    if Lark::Misc.require?('seer-hummer-trace-tools')
      run_podfile_pre_install_hook_method = instance_method(:run_podfile_pre_install_hook)
      define_method(:run_podfile_pre_install_hook) do |*args|
        time = Time.now
        run_podfile_pre_install_hook_method.bind(self).call(*args).tap {
          Seer::HumrTrace.custom_stage_dt('podfile_pre_install', (Time.now - time) * 1000)
        }
      end
    end
  end
end

# @!parse
#  # @param pathname [String, Pathname] the path to check
#  # @return [Boolean]
#  def Dir.exist?(pathname); end
