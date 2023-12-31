#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'pod_group'
require 'colored2'
# require 'cocoapods'
# require 'cocoapods-core'
require 'rubycli'

# 该脚本用于辅助同步arch/config 和 owner文档的一致性
#
# 使用文档：https://bytedance.feishu.cn/docx/doxcnnKGZlSZDYl0USdzXaTgNZd
# https://bytedance.feishu.cn/wiki/wikcnwChrVnETAotZdyqzditWAD?sheet=0eqWCG&table=tblwOALpOa0rqeqQ&view=vewTiR2kKw
# 文档更新同步操作:
# 1. doc_names, 从文档复制到脚本里(按名字排序). FIXME: 是否有open api可以自动读取同步?
# 2. (可选), 调用diff命令, 对比local_names和doc_names的差异, 对本地或者文档的数据进行清理和补齐同步
# 3. 调用layer或者biz命令，把输出同步覆盖到doc文档(需要保证doc_names的顺序一致，按列粘贴)
class App
  extend RubyCLI::DSL::Root

  namespace.desc '方便同步arch和doc文档的内容的辅助脚本'

  desc "output diff between arch, lock, and doc. you may copy doc names first\n doc url: https://bytedance.feishu.cn/wiki/wikcnwChrVnETAotZdyqzditWAD?sheet=0eqWCG&table=tblwOALpOa0rqeqQ&view=vewTiR2kKw"
  option %i[doc_data d], desc: 'doc_data数据对应的文件，应该从文档中复制对应的列. 使用-从stdin读取，+从剪贴板读取'
  switch %i[conflict c], desc: '输出架构标记的差异，需要复制从名字到归属列'
  def diff(doc_data:, conflict: nil)
    set_doc_data(doc_data)

    check_miss = lambda do
      arch_root_names = group_by_root_name.keys
      # strict_lock = YAML.load_file('Podfile.strict.lock')
      # strict_lock_pod_names = strict_lock.map { |v| v.split(' ', 2)[0] }

      doc_names = self.doc_names

      all_names = (arch_root_names | doc_names).sort
      # arch_miss = all_names - arch_root_names
      # strict_lock_miss = all_names - strict_lock_pod_names
      doc_miss = all_names - doc_names

      # puts "arch miss:".green.bold + "\n#{arch_miss.sort.join("\n")}\n\n" unless arch_miss.empty?
      # puts "lock miss:".green.bold + "\n#{strict_lock_miss.sort.join("\n")}\n\n" unless strict_lock_miss.empty?
      puts 'doc miss:'.green.bold + "\n#{doc_miss.sort.join("\n")}\n\n" unless doc_miss.empty?
    end

    check_conflict = lambda do
      # 计算属性一致性
      conflict_info = @doc_data.map do |doc_data|
        next unless doc_data
        arch_info = group_by_root_name[doc_data.name]
        next unless arch_info

        dl, db = doc_data.layer || '', doc_data.biz || ''
        al, ab = arch_info.layer || '', arch_info.biz || ''
        next if dl == al and db == ab
        "#{doc_data.name.blue.bold}: `#{"layer=#{dl},biz=#{db}".yellow.bold}` in doc VS `#{"layer=#{al},biz=#{ab}".green.bold}` in arch"
      end.compact
      unless conflict_info.empty?
        puts 'find conflict values for layer or biz, see below(DOC VS ARCH):'.green.bold
        puts conflict_info.join("\n")
      end
    end

    check_miss[]
    check_conflict[] if conflict
  end

  desc 'output layer value by doc names, you can pipe to pbcopy to save it in pasteboard'
  option %i[doc_data d], desc: 'doc_data数据对应的文件，应该从文档中复制对应的列. 使用-从stdin读取，+从剪贴板读取'
  def layer(doc_data:)
    set_doc_data(doc_data)
    puts @doc_data.map { |v| v&.then { group_by_root_name[v.name]&.layer }.to_s }.join("\n")
  end

  desc 'output biz value by doc names, you can pipe to pbcopy to save it in pasteboard'
  option %i[doc_data d], desc: 'doc_data数据对应的文件，应该从文档中复制对应的列. 使用-从stdin读取，+从剪贴板读取'
  def biz(doc_data:)
    set_doc_data(doc_data)
    puts @doc_data.map { |v| v&.then { group_by_root_name[v.name]&.biz }.to_s }.join("\n")
  end

  def set_doc_data(path)
    contents = case path
               when '-' then $stdin.read
               when '*', '+' then `pbpaste`
               when String then File.read(path)
               else raise "unsupported doc data arg: #{path}"
               end
    @doc_data = DocRow.from_lines(contents)
  end

  def doc_names
    @doc_data.map { |v| v&.name }.compact
  end

  def doc_info
    @doc_info ||= doc_names.each_with_object({}) do |n, h|
      h[n] = group_by_root_name[n] || ArchPodInfo.new(name: n)
    end
  end

  def group_by_root_name
    @group_by_root_name ||= begin
      info = YAML.load_file('config/arch.yml')['ARCH']
      groups_from_path = lambda do |path|
        path.split(',').to_h do |mark|
          key, value = mark.split('=', 2).map(&:strip)
          value = true if value.nil? # 没有设置value，默认为true
          [key, value]
        end
      end

      manager = PodGroup::Manager.new
      info.each do |path, pods|
        next unless pods.is_a? Array
        pods.each { |v|
          manager.set_pod(v, groups_from_path[path])
        }
      end

      v = manager.repository.each_with_object({}) do |(k, v), h|
        name = k.split('/', 2)[0]
        i = h[name] ||= ArchPodInfo.new(name: name)
        i.subspecs[k] = v
      end
      v
    end
  end
end

# 储存arch podname相关的信息
class ArchPodInfo
  attr_accessor :name
  attr_reader :subspecs

  def initialize(**options)
    @subspecs = {}
    options.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end
  def layer
    if s = subspecs[name]
      return s['layer']
    end
    subspecs.map { |_k, v| v['layer'] }.uniq.join(',')
  end
  def biz
    if s = subspecs[name]
      return s['biz']
    end
    subspecs.map { |_k, v| v['biz'] }.uniq.join(',')
  end
end

class DocRow
  attr_accessor :name, :owner, :state, :layer, :biz

  def initialize(*args)
    @name = args[0]&.strip
    @owner = args[1]&.strip
    @state = args[2]&.strip
    @layer = args[3]&.strip
    @biz = args[4]&.strip
  end
  def self.from_line(line)
    v = new(*line.split("\t"))
    return v if n = v.name and !n.empty?
  end
  # @return [Array<DocRow, nil>]
  def self.from_lines(contents)
    contents.each_line.map { |v| from_line(v) }
  end
end

App.run!
