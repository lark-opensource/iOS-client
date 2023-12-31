# frozen_string_literal: true

module Pod
  def self.load_plugins
    unless $load_plugins
      require 'cocoapods'
      %w[claide cocoapods].each do |plugin_prefix|
        CLAide::Command::PluginManager.load_plugins(plugin_prefix)
      end
      $load_plugins = true
    end
  end
end

class Query
  # @return [Query]
  def self.create_from_lockfile
    require 'cocoapods-core'
    require 'pod_group'
    # Pod.load_plugins
    lock = Pod::Lockfile.from_file(Pathname(File.expand_path('Podfile.lock', git_root)))
    graph = PodGroup::View.graph_from_lockfile(lock)
    group = get_group
    return new(graph, group)
  end

  def self.git_root
    @git_root ||= `git rev-parse --show-toplevel`.chomp
  end

  def self.get_group # rubocop:disable all
    arch = YAML.load_file(File.expand_path('config/arch.yml', git_root))
    info = arch['ARCH']

    groups_from_path = lambda do |path|
      path.split(',').to_h do |mark|
        key, value = mark.split('=', 2).map(&:strip)
        value = true if value.nil? # 没有设置value，默认为true
        [key, value]
      end
    end
    group = {}
    info.each do |path, pods|
      next unless pods.is_a? Array
      pods.each do |pod|
        (group[pod] ||= {}).update(groups_from_path.(path))
      end
    end
    group
  end
end
