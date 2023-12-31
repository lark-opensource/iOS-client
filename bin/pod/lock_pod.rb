#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cocoapods-core'

# 描述 Podfile.lock 里的 Pods
class LockPod
  attr_accessor :name, :version, :parents, :children

  def initialize(name, version = nil)
    @name = name
    @version = version
    @parents = Set.new
    @children = Set.new
  end

  # @param [Pathname] lock_path Podfile.lock 文件路径
  # @return [Array<LockPod>]
  def self.load_from_path(lock_path)
    raise "#{lock_path} does not exists" unless lock_path.exist?
    reader = LockReader.new(lock_path)
    reader.pod_map.values
  end
end

# 分析 Podfile.lock，提供 dependencies、reserve_dependencies 等信息
class LockReader
  # @param file_path [Pathname] path/to/Podfile.lock
  def initialize(file_path)
    @source_file = file_path
  end

  def lockfile
    @lockfile ||= Part::Lockfile.from_file(@source_file)
  end

  # @return [Hash<String, Pathname>]
  def local_pod_paths
    return @local_sources if @local_sources

    hash = lockfile.to_hash['EXTERNAL SOURCES'] || {}
    base_dir = @source_file.parent
    @local_sources =  hash.map do |key, val|
      return unless path = val[:path]
      [key, base_dir.join(path)]
    end.compact.to_h
  end

  # @return [Hash<String, LockPod>]
  def pod_map
    return @pod_map if @pod_map

    pods = {}

    # @type repr [String]
    # @return [String]
    parse_dep_name = lambda do |repr|
      match_data = repr.match(/\A((?:\s?[^\s(])+)(?: \((.+)\))?\Z/)
      raise "Unexpected string representation for a dependency: #{repr}" unless match_data
      match_data[1]
    end

    # @type arr [Array]
    arr = lockfile.to_hash['PODS']
    arr.each do |e|
      pod_repr, dep_reprs = case e
                            when String
                              [e, []]
                            when Hash
                              raise 'unexpected key count' unless e.keys.count == 1
                              [e.keys.first, e[e.keys.first]]
                            else
                              raise 'unexpected type'
                            end
      p_name, p_vers = ::Part::Spec.name_and_version_from_string(pod_repr)
      pods[p_name] ||= LockPod.new(p_name)
      pods[p_name].version = p_vers
      dep_reprs.each do |e|
        c_name = parse_dep_name.call(e)
        pods[c_name] ||= LockPod.new(c_name)
        pods[p_name].children << c_name if p_name != c_name
        pods[c_name].parents << p_name if p_name != c_name
      end
    end
    @pod_map = pods
  end
end

class DepPrinter

  # @param file_path [Pathname] path/to/Podfile.lock
  def initialize(file_path)
    @source_file = file_path
  end

  def lock_reader
    @lock_reader ||= LockReader.new(@source_file)
  end

  # 提取 target 的所有依赖
  #
  # @type target [String] target pod name
  def print_dependencies(target, **opt)
    raise "cannot find #{target} in Podfile.lock".red unless lock_reader.pod_map.include?(target)

    ret = find_dependencies(target, :children)
    pretty_print_chains(ret.values.sort, **opt)
  end

  # 提取依赖（包括直接依赖或间接依赖） target 的所有 pods
  #
  # @param target [String] target pod name
  # @return [Set<String>]
  def print_reserve_dependencies(target, **opt)
    raise "cannot find #{target} in Podfile.lock".red unless lock_reader.pod_map.include?(target)
    ret = find_dependencies(target, :parents)
    pretty_print_chains(ret.values.sort, **opt)
  end

  # @param chains [Array<String>]
  def pretty_print_chains(chains, **opt)
    items = chains.map do |chain|
      comps = chain.split(':').reject(&:empty?)
      LevelPrintItem.new(comps.count - 1, comps[-1])
    end
    level_print(items, opt[:max_depth].to_i)
  end

  # 查询依赖
  #
  # @param target [String] target pod name
  # @param sel [Symbol] :parents | :children
  # @return [Hash<String, String>]
  #   hash: key - pod name, value - dep chain
  #   譬如：对于 target `RustPB`， { 'protobuf_lite' => ':TTNetworkManager:TTNetworkManager/Core:protobuf_lite' }
  #        表示 RustPB 对 `protobuf_lite` 的依赖关系为：
  #        RustPB -> TTNetworkManager -> TTNetworkManager/Core -> protobuf_lite
  def find_dependencies(target, sel)
    # key: pod name, value: chain
    ret = {}
    traverse = lambda do |name, chain|
      exist = ret[name]
      # 如果已经存在，则保留路径更短的那一个
      return if !exist.nil? && exist.split(':').count <= chain.split(':').count
      raise "something wrong. pod_map should contains item named #{name}" unless lock_reader.pod_map[name]

      ret[name] = chain
      lock_reader.pod_map[name].send(sel).each { |p| traverse.call(p, chain + ":#{p}") }
    end
    traverse.call target, ''
    ret.delete target
    ret
  end

  # @param level [Number] 层级，从 0 开始
  # @param text [String] 内容
  LevelPrintItem = Struct.new(:level, :text)

  # using Colorize

  def color_codes
    @color_codes ||= {
      :black   => '0;30',
      :red     => '0;31',
      :green   => '0;32',
      :brown   => '0;33',
      :blue    => '0;34',
      :purple  => '0;35',
      :cyan    => '0;36',
      :white   => '0;37',
      :default => '0;32'
    }
  end

  def colorize(str, color_code)
    code = color_codes[color_code] || color_codes[:default]
    "\e[#{code}m#{str}\e[0m"
  end

  # @param items [Array<LevelPrintItem>]
  # @param max_depth [Number] max depth
  def level_print(items, max_depth)
    bullet = '•'
    level_colors = %i[red green brown blue purple cyan]
    items.each do |item|
      level = item.level
      next unless level < max_depth
      text = item.text
      color = level_colors[level % level_colors.count]
      puts "#{" " * level * 4} #{colorize(bullet + ' ' + text, color.to_sym)}"
    end
  end
end
