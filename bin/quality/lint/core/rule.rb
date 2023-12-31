#!/usr/bin/env ruby
# frozen_string_literal: true
require 'set'
require_relative './base'
require_relative '../../util/req'

# 规则
class Rule
  module Level
    P0 = 'P0'
    P1 = 'P1'
    P2 = 'P2'
    P3 = 'P3'
  end

  def self.category_ch_name(category_name)
    @category_map ||= {
      'defect' => '代码缺陷',
      'security' => '安全漏洞',
      'maintenance' => '可维护性',
      'code_style' => '代码风格',
      'performance' => '代码性能',
      'usability' => '可用性',
      'compatibility' => '兼容性',
      'i18n' => '国际化',
      'accessibility' => '可访问性',
      'other' => '其他'
    }
    return @category_map[category_name] || category_name
  end

  module Scene
    CI = '持续集成'
    DB = 'DailyBuild'
  end

  attr_accessor :id, :name, :level, :engine, :category

  def to_s
    "{ id: #{id}, name: #{name}, level: #{level}, engine: #{engine}, category: #{category} }"
  end

  # @param [Integer] app_id
  # @param [String] scene Scene::CI || Scene::DB
  # @return [Array<Rule>]
  def self.load_rules(app_id:, scene:)
    url_base = "https://codebase.byted.org/analysis/api/v3/unstable/applications/#{app_id}/scenes"
    uri =
      if scene == Scene::CI
        URI("#{url_base}/merge_check/rules")
      else
        URI("#{url_base}/quality_analysis/rules")
      end
    req = Net::HTTP::Get.new(uri).json!
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    rule_list_raw = JSON.parse(res.body) || []
    rule_list_raw.map do |hash|
      raw = hash['rule']
      raise "unexpected hash: #{hash}" unless raw.is_a?(Hash) && %w[id name severity driver_name].to_set < raw.keys.to_set

      severity = hash&.dig('self')&.dig('severity')  || raw['severity']

      rule = Rule.new
      rule.id = raw['external_uid'] || raw['id']
      rule.name = raw['name']
      rule.engine = raw['driver_name']
      rule.category = raw['category']
      rule.category = category_ch_name(rule.category) unless rule.category.nil? || rule.category.empty?
      rule.level =
        case severity
        when 'critical'
          Level::P0
        when 'error'
          Level::P1
        when 'warning'
          Level::P2
        when 'info'
          Level::P3
        else
          abort('unexpected level')
        end
      rule
    end
  end
end
