#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'colored2'
require 'set'

require_relative './lock_pod'
require_relative './wiki_pod'

class WikiChecker

  # @param [Pathname] lock_path
  def initialize(lock_path)
    @lock_path = lock_path
  end

  def lock_pods
    @lock_pods ||= LockPod.load_from_path @lock_path
  end

  def wiki_pods
    @wiki_pods ||= WikiPod.load_from_server
  end

  InvalidItem = Struct.new(:pod, :desc)

  def run
    ######## 1. check missing ########
    # 1.1 load lock pods
    all_pods = lock_pods.map { |pod| pod.name.split('/').first }.uniq.sort
    missing = all_pods - wiki_pods.map(&:name)

    ######## 2. check invalid ########
    ignore_states = Set['已废弃', '待废弃']
    # 二、三方的 pod，暂不检查 owner
    second_thrid_bizs = Set['SecondPart/ByteDance', 'SecondPart/Toutiao', 'SecondPart/IES', 'ThirdPart/SDK', 'ThirdPart/OpenSource']
    invalid = wiki_pods.map do |pod|
      next if ignore_states.include?(pod.status)
      desc = []
      unless pod.biz.is_a?(String) and !pod.biz.empty?
        desc << '没指定业务'
      end
      if !second_thrid_bizs.include?(pod.biz)
        unless pod.owners.is_a?(Array) and !pod.owners.empty?
          desc << '缺少 owner'
        end
      end
      unless desc.empty?
        InvalidItem.new(pod, desc)
      end
    end.compact

    if missing.empty?
      puts "check missing, succeed.".green.bold
    else
      puts "check missing, failed. pods: ".red.bold + missing.join(',')
    end

    if invalid.empty?
      puts "check invalid, succeed.".green.bold
    else
      invalid_list = invalid
      ## .filter { |item| !ignore_states.include?(item.state) && !ignore_bizs.include?(item.biz) }
                       .map do |item|
        "  - #{item.pod.name}: #{item.desc.join("，")}"
      end
      puts "check invalid, failed. pods:\n".red.bold + invalid_list.join("\n")
    end
  end
end
