#!/usr/bin/env ruby
require 'json'
require_relative './lib/config'
require_relative './lib/utils'

MODE_PATH = OwnerConfig::ExtraConfig::Rule::MODE::PATH

# 检查输入参数
unless (output_path = ARGV[0])
  puts "Usage: get_owner_info.rb <output_path>"
  exit 1
end

# 加载配置文件
pods_config = OwnerConfig::PodsConfig.load_file('config/pod_owner.yml')
custom_config = OwnerConfig::ExtraConfig.load_file('config/extra_owner.yml')

# 建立 name 到 path 的映射
pod_path_map = OwnerConfig::Utils.pod_path_map

# 获取 pod_owners 数据
pod_data =
  pods_config.pods.map { |name, pod|
    module_identifier = "module:#{name}"
    data = {
      "owner": pod.owner_as_emails,
      "org": pod.team
    }

    if pod_path_map.key?(name)
      path_identifier = "path://iOS-client/#{pod_path_map[name]}"
      [[module_identifier, data], [path_identifier, data]]
    else
      [[module_identifier, data]]
    end
  }.flatten(1).to_h

# 获取 extra_owners 数据
custom_data =
  custom_config
    .flattened_pattern_to_rule
    .select { |_, rule| rule.mode == MODE_PATH }
    .map { |path, rule|
      identifier = "path://iOS-client/#{path}"
      data = {
        "owner": rule.owner_as_emails,
        "org": rule.team
      }

      [identifier, data]
    }
    .to_h

# 若 custom_data 包含与 pod_data 相同的 path, 会覆盖 pod_data 中的 path
final_data = pod_data.merge(custom_data)

# 写入目标文件
File.write(output_path, JSON.dump(final_data))
