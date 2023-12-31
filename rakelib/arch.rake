# frozen_string_literal: true

# @!domain [Rake::DSL]

desc '使用Podfile.lock中的依赖关系，检测config/arch.yml中的标注是否有错误的依赖问题'
task check_arch_dependency: :prepare_cocoapods do
  podfile = Pod::Config.instance.podfile
  group = podfile.pod_group_manager.repository
  graph = PodGroup::View.graph_from_lockfile(Pod::Config.instance.lockfile)
  podfile.lark_check_arch_dependency(graph, group, $lark_env.check_arch_rules)
  Pod::UI.print_warnings
end

# 输出只被单一业务线使用的通用库, 帮助review pod的架构层级
task common_pod_use_by_single_biz: :prepare_cocoapods do
  podfile = Pod::Config.instance.podfile
  group = podfile.pod_group_manager.repository
  graph = PodGroup::View.graph_from_lockfile(Pod::Config.instance.lockfile)

  checker = PodGroup::Check::Checker.new(graph: graph, groups: group)
  layer_values = $lark_env.check_arch_rules['$LAYER'].each_with_index.to_h
  platform_layer_value = layer_values['platform']
  # biz_layer_value = Pod::Podfile::GraphNodeWrapper::LayerValues['biz']
  # 只关注我们业务的库，二方三方的库不管
  lark_biz_value = Set.new %w[
    messenger calendar doc mail app byteview meego lark
  ]
  lark_biz_value.add(nil)

  output_pod = proc do
    # @param [Molinillo::DependencyGraph::Vertex]
    pod_use_by_single_biz = []
    checker.each do |n|
      # 需要被检测
      next unless (nlv = layer_values[n['layer']]) >= platform_layer_value and lark_biz_value.include? n['biz']
      # 使用方没有同层级
      predecessors = n.predecessors
      next unless predecessors.all? { |v| layer_values[v['layer']] < nlv }

      #  集成层的业务线如果依赖也可能导致裁剪，所以也要考虑是否可以直接依赖
      predecessors_biz_values = predecessors.map { |v| v['biz'] }.uniq
      # binding.pry if n.name.include? 'LarkBytedCert'
      pod_use_by_single_biz.push [n, predecessors_biz_values.first] if predecessors_biz_values.size < 2
    end
    next if pod_use_by_single_biz.empty?
    puts "以下组件可提升至业务层:\n#{pod_use_by_single_biz.map { |v| "  - #{v[0].name}(#{v[1]})" }.join("\n")}"

    next # 暂时不递归判断，因为大部分库的层级没有问题..

    # 检测如果这个库移动上去后是否有新的库可以移动上去
    # pod_use_by_single_biz.each do |n, biz|
    #   n.instance_exec do
    #     @layer = 'biz-i'
    #     @biz = biz
    #   end
    # end
    # output_pod.call
  end
  output_pod.call
end

task pod_without_platform_dependency: :prepare_cocoapods do
  podfile = Pod::Config.instance.podfile
  group = podfile.pod_group_manager.repository
  graph = PodGroup::View.graph_from_lockfile(Pod::Config.instance.lockfile)

  checker = PodGroup::Check::Checker.new(graph: graph, groups: group)
  layer_values = $lark_env.check_arch_rules['$LAYER'].each_with_index.to_h
  component_layer_value = layer_values['component']

  output_pod = proc do
    # @param [Molinillo::DependencyGraph::Vertex]
    pod_without_platform_dependency = []
    checker.each do |n|
      # 需要被检测
      next unless layer_values[n['layer']] < component_layer_value
      # 使用方没有同层级
      successors = n.successors
      next unless successors.all? { |v| layer_values[v['layer']] >= component_layer_value }

      pod_without_platform_dependency.push n
    end
    next if pod_without_platform_dependency.empty?
    puts "以下组件没有组件层以外的依赖:\n#{pod_without_platform_dependency.map { |v| "  - #{v.name}(#{v['layer']})" }.join("\n")}"

    next # 暂时不递归判断，因为大部分库的层级没有问题..
  end
  output_pod.call
end
