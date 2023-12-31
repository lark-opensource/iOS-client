#!/usr/bin/env ruby

# frozen_string_literal: true

require 'pathname'

# 描述 Pod 的声明定义
#
# @param name [String] pod name
# @param version [String | Void] pod version
# @param file [String] file path
# @param line [Number] line number
PodDef = Struct.new(:name, :version, :file, :line)

def err_exit(msg)
  puts "\e[31m#{msg}\e[0m"
  exit 1
end

# 某些 pod 考虑海内外场景，允许有不同版本定义
MULTI_VERS_WHITE_LIST = %w[
  IESGeckoKit
  LarkFlutterContainer
  Quaterback
]

# 检查 pod 版本信息，做了如下约束：
#   1. 不能同时写多个版本约束
#   2. 版本约束要求尽可能写在 if_pod.rb 中，而不是 Podfile（还有一些特殊 case，目前还未做强约束）
#
# @param proj_dir [Pathname] 工程根目录
def check_pod_version(proj_dir)
  err_exit "#{proj_dir.to_s} is not valid" unless proj_dir.directory?

  space = '[\s\t]'
  quota = '["\']'
  name = '[\w.]+'
  version = '[\s\t\w\.-]'
  reg = /^#{space}*(?<def>pod|if_pod)#{space}+#{quota}(?<name>#{name})#{quota}#{space}*(:?,#{space}*#{quota}(?<version>#{version}+)#{quota})?/

  # @type [Hash<String, PodDef>] pods_info_in_ifpod if_pod.rb 中声明的 pod 信息
  pods_info_in_ifpod = Hash.new

  if_pod_path = proj_dir.join('if_pod.rb').to_s
  File.readlines(if_pod_path, :encoding => 'UTF-8').each_with_index do |line, index|
    ret = reg.match line
    next if ret.nil?

    name = ret['name'].strip
    next if name.nil?

    old = pods_info_in_ifpod[name]
    new = PodDef.new(name, ret['version']&.strip, if_pod_path, index + 1)
    if old.nil?
      pods_info_in_ifpod[name] = new
    else
      if !old.version.nil? && !new.version.nil? && !MULTI_VERS_WHITE_LIST.include?(name)
        err_exit "#{name}在if_pod.rb中被多次指定版本号：第#{old.line}行和第#{new.line}行，有疑问请联系 zhangwei.wy"
      end
      pods_info_in_ifpod[name] = new if old.version.nil?
    end
  end

  last_target = nil
  target_reg = /^#{space}*target#{space}+#{quota}(?<target>\w+)#{quota}#{space}+do/
  podfile_path = proj_dir.join('Podfile').to_s
  File.readlines(podfile_path, :encoding => 'UTF-8').each_with_index do |line, index|
    # 找到匹配 `target 'Lark' do` 的 line
    if last_target.nil?
      ret = target_reg.match line
      last_target = ret['target'] unless ret.nil?
      next
    end

    break if last_target != 'Lark'

    ret = reg.match line
    if ret.nil?
      if target_reg.match(line)  # 匹配到了其他的 target
        break 
      else
        next
      end
    end

    name = ret['name'].strip
    next if name.nil?

    old = pods_info_in_ifpod[name]
    new = PodDef.new(name, ret['version']&.strip, podfile_path, index + 1)

    err_exit "#{name}已经在if_pod.rb（第#{old.line}行）中被定义，不要再在 Podfile 中定义了" if !old.nil? && !new.version.nil?
  end
end

check_pod_version Pathname.new(ARGV[0])
