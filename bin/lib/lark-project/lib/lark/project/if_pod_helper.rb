# frozen_string_literal: true

# 这个文件里定义if_pod需要的一些帮助脚本，比如if_pod的拦截和优先级定义实现

module Pod
  module IfPodRefine
    refine Podfile do
      # 使用refine，限制这个文件内定义的if_pod优先级低于Podfile里的
      def if_pod(name, *requirements)
        if_pod_cache << [current_target_definition, name, *requirements]
      end
      def pod(name, *)
        raise "shouldn't use pod '#{name}' in if_pod.rb files"
      end
    end
  end
  class Podfile
    # 这下面使用的if_pod会保存到if_pod_cache里，延迟生效. (如果Podfile里有定义，Podfile的定义优先)
    def if_pod_cache
      @if_pod_cache ||= begin
        defer_actions << proc { flush_if_pod_define! }
        []
      end
    end

    def disable_if_pod(*root_names)
      (@disable_if_pod ||= Set.new).merge(root_names)
    end

    def enable_local_if_pod(value = true) # rubocop:disable all
      @enable_local_if_pod = value
    end

    def flush_if_pod_define! # rubocop:disable all
      return if if_pod_cache.empty?

      # @type [LarkModule::Manager]
      manager = Config.instance.module_manager
      # 如果podfile有定义(只是加根依赖但不限制除外)，Podfile的定义优先
      # 版本限制和额外集成分开计算, 额外集成按相同label计算
      version_defined = dependencies.reject do |dep|
        dep.external_source.nil? && dep.requirement.none? && dep.podspec_repo.nil?
      end.to_set(&:root_name)
      version_defined.merge(manager.pod_requirements_by_root_name.keys)

      # extra_integration = manager.explicit_dependencies.transform_values do |deps|
      #   deps.map { |dep| dep.root_name  }
      # end
      extra_integration = (manager.subspec_relatives.keys + manager.pod_relative.keys).to_set { |v|
        Specification.root_name(v)
      }

      disabled = @disable_if_pod || []

      if_pod_cache.each do |target, name, *requirements|
        root_name = Specification.root_name(name)
        if disabled.include?(root_name) or
           (extra_integration.include?(root_name) && version_defined.include?(root_name))
          next
        end

        # 这里可能有其他配置，比如inhibit warnning, 目前是跟着版本走的..
        options = requirements.last
        # @type [Hash]
        options = {} unless options.is_a? Hash
        # 额外依赖被覆盖
        if !options.empty? and extra_integration.include?(root_name)
          options.delete(:subspecs)
          options.delete(:pods)
          requirements.pop if options.empty?
        end
        # 版本限制被覆盖, 只包含集成数据
        if version_defined.include?(root_name)
          options = options.slice(:subspecs, :pods)
          next if options.empty?
          requirements = [options]
        end
        # 本地依赖在子仓不引入(因为找不到)
        if !@enable_local_if_pod && !options.empty?
          options.delete(:path)
          requirements.pop if options.empty?
        end
        next if requirements.empty?

        requirements = replace_with_local(name, requirements)
        target.store_if_pod(name, *requirements)
      end
    end
  end
end
