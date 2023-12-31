# frozen_string_literal: true

require 'cocoapods'

module Pod
  class Installer
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
  class Target
    class BuildSettings
      class AggregateTargetSettings
        # 用户注入的xcconfig配置, 避免提前修改触发xcconfig的生成
        def custom_xcconfig
          @custom_xcconfig ||= {}
        end

        raw_xcconfig_method = instance_method(:_raw_xcconfig)
        define_method(:_raw_xcconfig) do |*args|
          xcconfig = raw_xcconfig_method.bind(self).call(*args)
          if @custom_xcconfig && !@custom_xcconfig.empty?
            xcconfig = merge_spec_xcconfig_into_xcconfig(@custom_xcconfig, xcconfig)
          end
          xcconfig
        end
      end
      class PodTargetSettings
        raw_module_map_file_to_import_method = instance_method(:_raw_module_map_file_to_import)
        define_method(:_raw_module_map_file_to_import) do |*args|
          if path = target.force_static_module_map_file_to_link
            return "${PODS_ROOT}/Headers/Public/#{target.product_module_name}/#{target.label}.modulemap"
          end
          raw_module_map_file_to_import_method.bind(self).call(*args)
        end

        raw_swift_include_paths_to_import_method = instance_method(:_raw_swift_include_paths_to_import)
        define_method(:_raw_swift_include_paths_to_import) do |*args|
          if path = target.force_static_module_map_file_to_link
            return "${PODS_ROOT}/Headers/Public/#{target.product_module_name}"
          end

          raw_swift_include_paths_to_import_method.bind(self).call(*args)
        end
      end
    end
  end
  class AggregateTarget
    # @yieldparam [String]
    # @yieldparam [Target::BuildSettings::AggregateTargetSettings]
    def each_build_setting(&block)
      @build_settings.each(&block)
    end
  end
  class PodTarget
    # @return [Pathname] module map will link to Public/module folder
    # NOTE: not in private, since public and private path are different, may cause duplicate definition
    attr_accessor :force_static_module_map_file_to_link
  end
  class Installer
    class Xcode
      class PodsProjectGenerator
        class PodTargetInstaller
          install_method = instance_method(:install!)
          define_method(:install!) do |*args|
            install_method.bind(self).call(*args).tap do |result|
              # 使用自定义的custom_module_map强制覆盖，并放入public/module中
              # 主要针对的是静态库不需要编译的场景
              # 另外pre install前生成会莫名丢失，可能是插件兼容性问题，改成target install时生成软链接
              next unless custom_module_map = target.force_static_module_map_file_to_link

              path = target.module_map_path_to_write
              UI.message "- Copying module map file to #{UI.path(path)}" do
                contents = custom_module_map.read
                # 二进制产物始终使用module, 而不是framework module
                contents.gsub!(/^(\s*)framework\s+(module[^{}]+){/, '\1\2{')
                generator = Generator::Constant.new(contents)
                update_changed_file(generator, path)
                add_file_to_support_group(path)

                # 始终放入public，这样可以把public header的依赖自动转化为module依赖
                basename = "#{target.label}.modulemap"
                linked_path = sandbox.public_headers.root + target.product_module_name + basename
                if path != linked_path
                  linked_path.dirname.mkpath
                  source = path.relative_path_from(linked_path.dirname)
                  FileUtils.ln_sf(source, linked_path)
                end

                relative_path = target.module_map_path.relative_path_from(sandbox.root).to_s
                result.native_target.build_configurations.each do |c|
                  c.build_settings['MODULEMAP_FILE'] = relative_path.to_s
                end
              end
            end
          end
        end
      end
    end
  end

  module Downloader    
    class Cache
        if (ENV["External_SOURCE_BOOT"] || "true") == "true"
          git_root_dir = (`git rev-parse --show-toplevel`.presence || `git rev-parse --show-superproject-working-tree`).strip
          origin_method = instance_method(:cached_pod)
          define_method(:cached_pod) do |*args|
            request = args.first
            unless request.spec.nil? or request.spec.eesc_binary?
              local_spec_dir = Pathname.new(git_root_dir).join('external').join(request.spec.name)
              local_spec_path = local_spec_dir.join(request.spec.name + '.podspec.json')
              if File.exist? local_spec_path
                local_spec = Specification.from_file(local_spec_path)
                if local_spec.version.to_s == request.spec.version.to_s
                  UI.puts("Using external source to boost for #{request.name} downloading")
                  return Response.new(local_spec_dir, request.spec, request.params)
                end
              end
            end
            origin_method.bind(self).call(*args)
          end  
        end                  
    end
  end
  
  module UI
    warn_method = method(:warn)
    define_singleton_method(:warn) do |message, *args|
      warn_method.call(message, *args) unless !!$pod_ui_filter&.call(message) == true
    end
  end

  class DSLError
    def backtrace
      underlying_exception.backtrace || super
    end
  end
end
