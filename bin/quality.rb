#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'colored2'
require 'rubycli'

class App
  extend RubyCLI::DSL::Root

  namespace.desc '封装一些代码质量相关工具'

  def make_tmp_dir
    require 'tmpdir'
    Dir.mktmpdir
  end

  # @param [String] target_dir
  # 从 tos 拉取，准备脚本
  def load_script(target_dir:)
    system <<-QUALITY
    curl -fsSL http://tosv.byted.org/obj/ee-infra-ios/quality.tar.xz -o '#{target_dir}/quality.tar.xz'
    tar -xzf '#{target_dir}/quality.tar.xz' -C '#{target_dir}'
    QUALITY
    "#{target_dir}/quality"
  end

  desc "更新 lint issue 相关数据"
  option %i[type t], desc: 'type'
  def lint(type:)
    tmp_dir = make_tmp_dir
    ruby_base_path = load_script(target_dir: tmp_dir)

    require "#{ruby_base_path}/lint/list"
    # require_relative './quality/lint/list'

    type = type.downcase
    opts = nil
    if type.include? '/pod/'
      opts = { 'mod_parser_path' => Pathname(__dir__).join('quality/util/parser.rb').to_s }
    end
    update_bitable_by_key(type, opts: opts)
  end

  desc "更新 q2 的可读性数据"
  option %i[type t], desc: 'type'
  def readability_q2(type: 'all')
    require_relative './quality/readability/q2'
    case type.downcase
    when 'all'
      update_all_projs
    when 'ios/foundation', 'ios/infra', 'ios/messenger'
      repo_path = Pathname(__dir__).parent.to_s
      @wiki_pod_map = nil
      Pod.default_owner_for_key = lambda do |pod_name|
        @wiki_pod_map ||= WikiPod.load_from_server.group_by(&:name)
        return unless wiki_pod = @wiki_pod_map[pod_name]&.first
        # @type [WikiPod.User] owner
        return unless owner = wiki_pod.owners&.first

        [owner.id, owner.name]
      end
      proj_names = {
        'ios/foundation' => 'Modules/Foundation',
        'ios/infra' => 'Modules/Infra',
        'ios/messenger' => 'Modules/Messenger',
      }
      update_proj_pods(proj_name: proj_names[type], repo_path: repo_path)
    when 'ios/hz'
      update_hz_pods
    when 'android/hz'
      update_hz_mods
    else
      raise "unsupported type: #{type}"
    end
  end

  desc "更新 q2 的可读性数据"
  option %i[type t], desc: 'type'
  def q2(type: 'all')
    readability_q2(type: type)
  end
end

App.run!
