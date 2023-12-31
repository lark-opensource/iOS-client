#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'colored2'
require 'rubycli'

class App
  extend RubyCLI::DSL::Root

  namespace.desc '封装一些 pod 工具'

  def lock_path
    return @lock_path unless @lock_path.nil?
    lock_path = Pathname('./Podfile.lock')
    raise '请在 ios-client 根目录下执行' unless lock_path.exist?
    @lock_path = lock_path
  end

  # 检查 wiki 里的 组件 owner 列表
  desc "检查 Wiki 里的 pod 信息：https://bytedance.feishu.cn/wiki/wikcnwChrVnETAotZdyqzditWAD?sheet=0eqWCG&table=tblwOALpOa0rqeqQ&view=vewTiR2kKw"
  def check_wiki
    require_relative './pod/check_wiki'
    WikiChecker.new(lock_path).run
  end

  desc "获取 pod 信息，从组件列表提取"
  option %i[name n], desc: 'pod name'
  def info(name:)
    require_relative './pod/wiki_pod'
    target = WikiPod.load_from_server
                    .select { |pod| pod.name == name }
                    .first
    if target.nil?
      puts "Cannot find pod named #{name}" if target
    else
      puts "name: #{target.name}"
      puts "owners: #{target.owners.map(&:name)}"
      puts "biz: #{target.biz}" unless target.biz.nil? || target.biz&.empty? || false
      puts "desc: #{target.desc}" unless target.desc.nil? || target.desc&.empty? || false
      puts "status: #{target.status}" unless target.status.nil? || target.status&.empty? || false
      puts "layer: #{target.layer}" unless target.layer.nil? || target.layer&.empty? || false
    end
  end

  desc "list dependencies for specified pod"
  option %i[name n], desc: 'pod name'
  option %i[depth d], desc: 'max display depth, default is 999'
  def dep(name:, depth: 999)
    require_relative './pod/lock_pod'
    DepPrinter.new(lock_path).print_dependencies(name, max_depth: depth)
  end

  desc "list reserve dependencies for specified pod"
  option %i[name n], desc: 'pod name'
  option %i[depth d], desc: 'max display depth, default is 999'
  def rdep(name:, depth: 999)
    require_relative './pod/lock_pod'
    DepPrinter.new(lock_path).print_reserve_dependencies(name, max_depth: depth)
  end
end

App.run!
