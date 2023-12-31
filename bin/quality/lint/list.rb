#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative '../util/req'
require_relative '../util/bitable'
require_relative '../util/sheet'
require_relative './core/base'
require_relative './core/rule'
require_relative './core/repo'
require_relative './core/issue'

class RuleInfoItem
  attr_accessor :repo, :rule, :enable_in_ci, :enable_in_db

  # @param [Repo] repo
  # @param [Rule] rule
  def initialize(repo:, rule:)
    @repo = repo
    @rule = rule
    @enable_in_ci = false
    @enable_in_db = false
  end

  def gen_bitable_record
    fields = {}
    fields['规则'] = {
      'text': rule.name,
      'link': RuleInfoItem.gen_lint_url(app_id: repo.app_id, rule_id: rule.id)
    }
    fields['级别'] = rule.level
    fields['引擎'] = rule.engine
    fields['持续集成'] = true if enable_in_ci
    fields['每日扫描'] = true if enable_in_db
    fields['查看存量问题'] = {
      'text': '查看存量问题',
      'link': RuleInfoItem.gen_issue_url(app_id: repo.app_id, rule_id: rule.id)
    } if enable_in_db
    fields['类别'] = rule.category unless rule.category.nil?
    { 'fields': fields }
  end

  def self.gen_lint_url(app_id:, rule_id:)
    "#{VIEW_URL_BASE}/compliance/static_analysis/scan_plan/rule/#{rule_id}?appId=#{app_id}"
  end

  def self.gen_issue_url(app_id:, rule_id:)
    base_path = "#{VIEW_URL_BASE}/compliance/static_analysis"
    query = {
      'appId': app_id,
      'ruleDisplayType': 'set',
      'status': 'total',
      'tabKey': 'issueList',
      'viewType': 'all'
    }.map { |key, value| "#{key}=#{value}" }.join('&')
    query << "&rule_ids[]=#{rule_id}"
    "#{base_path}?#{query}"
  end
end

class RuleIssueCountItem
  attr_accessor :repo, :rule, :count

  # @param [Repo] repo
  # @param [Rule] rule
  # @param [Integer] count
  def initialize(repo:, rule:, count:)
    @repo = repo
    @rule = rule
    @count = count
  end

  def gen_bitable_record
    fields = {}
    fields['规则'] = {
      'text': rule.name,
      'link': RuleInfoItem.gen_lint_url(app_id: repo.app_id, rule_id: rule.id)
    }
    fields['问题数量'] = count
    fields['查看明细'] = {
      'text': '查看存量明细',
      'link': RuleInfoItem.gen_issue_url(app_id: repo.app_id, rule_id: rule.id)
    }
    { 'fields': fields }
  end
end

class ModIssueCountItem
  attr_accessor :repo, :name, :count, :owner, :biz, :issue_link

  # @param [Repo] repo
  # @param [String] name
  # @param [Hash | nil] owner
  # @param [String | nil] issue_link
  def initialize(repo:, name:, count:, owner: nil, biz: nil, issue_link: nil)
    @repo = repo
    @name = name
    @count = count
    @owner = owner
    @biz = biz
    @issue_link = issue_link
  end

  def gen_bitable_record
    fields = {}
    fields['组件'] = name
    fields['问题数量'] = count
    fields['责任人'] = [owner] if owner
    fields['所属业务'] = biz if biz
    fields['查看明细'] = { 'text': '查看存量明细', 'link': issue_link } if issue_link
    { 'fields': fields }
  end
end

def update_mod_issue_bitable(repo:, level:, bitable_token:, bitable_table_id:, mod_parser:)
  # 1. fetch issues
  fetcher = Issue::Fetcher.new(app_id: repo.app_id)
  batch_id = Repo::Fetcher.new(app_id: repo.app_id).fetch_latest_batch_id
  issues = fetcher.fetch_issues_by_levels([level], batch_id: batch_id.to_i)

  # 2. group issues
  grouped_issues = {}
  mod_paths = {}  # 记录 mod 的相对路径，key: mod_name, value: mod_path
  issues.each do |issue|
    mod_ret = mod_parser.find_mod(issue.path)
    mod_name = mod_ret&.first || 'Unknown'
    grouped_issues[mod_name] ||= []
    grouped_issues[mod_name] << issue

    mod_paths[mod_name] = mod_ret&.last if mod_paths[mod_name].nil?
  end

  # @type [Array<ModIssueCountItem>] mods
  gen_issue_link = lambda do |mod_name|
    mod_path = mod_paths[mod_name]
    return if mod_path.nil?

    link = "#{VIEW_URL_BASE}/compliance/static_analysis?appId=#{repo.app_id}&&batch_id=#{batch_id}".dup
    link << "&file_names[]=#{URI.encode_www_form_component(mod_path)}"
    link << "&levels[]=#{level}"
    link << '&page_num=1'
    link << '&ruleDisplayType=set'
    link << '&status=unsolve'
    link << '&tabKey=issueList'
    link << '&viewType=all'
    link
  end
  mods = []
  get_mod_biz = lambda do |mod_name|
    mod_parser.biz_for_mod(mod_name) if mod_parser.respond_to?(:biz_for_mod)
  end
  grouped_issues.each do |mod_name, _issues|
    mods << ModIssueCountItem.new(
      repo: repo,
      name: mod_name,
      count: _issues.length,
      owner: mod_parser.owners_for_mod(mod_name).first,
      biz: get_mod_biz.call(mod_name),
      issue_link: gen_issue_link.call(mod_name)
    )
  end
  mods.sort_by!(&:count).reverse!

  # token 获取方式详见：https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/bitable/notification#484df303
  bitable = Bitable.new(token: bitable_token, table_id: bitable_table_id)
  # bitable.load_records.each { |record| Part.cache_preferred_owners record }
  bitable.clean_records
  bitable.upload(records: mods.map(&:gen_bitable_record))
end

# @param [Repo] repo
# @param [String] level
# @param [String] token
# @param [String] table_id
def update_rule_issue_bitable(repo:, level:, token:, table_id:)
  rules = Rule.load_rules(app_id: repo.app_id, scene: Rule::Scene::DB).filter { |r| r.level == level }

  fetcher = Issue::Fetcher.new(app_id: repo.app_id)
  batch_id = Repo::Fetcher.new(app_id: repo.app_id).fetch_latest_batch_id
  # @type [Array<RuleIssueCountItem>] items
  items = rules.map do |rule|
    count = fetcher.fetch_issue_count_by_rule(rule, batch_id: batch_id.to_i)
    RuleIssueCountItem.new(repo: repo, rule: rule, count: count)
  end.filter { |item| !item.count.zero? }
  items.sort_by!(&:count).reverse!

  bitable = Bitable.new(token: token, table_id: table_id)
  bitable.clean_records
  bitable.upload(records: items.map(&:gen_bitable_record))
end

# @param [Repo] repo
# @param [String] bitable_token
# @param [String] bitable_table_id
# @return [Array<RuleInfoItem>]
def update_all_rule_bitable(repo:, bitable_token:, bitable_table_id:)
  # 1. get all rules
  items = {}
  Rule.load_rules(app_id: repo.app_id, scene: Rule::Scene::CI).each do |rule|
    items[rule.id] = RuleInfoItem.new(repo: repo, rule: rule)if items[rule.id].nil?
    items[rule.id].enable_in_ci = true
  end
  Rule.load_rules(app_id: repo.app_id, scene: Rule::Scene::DB).each do |rule|
    items[rule.id] = RuleInfoItem.new(repo: repo, rule: rule) if items[rule.id].nil?
    items[rule.id].enable_in_db = true
  end

  # 2. update bitable
  bitable = Bitable.new(token: bitable_token, table_id: bitable_table_id)
  bitable.clean_records
  bitable.upload(records: items.values.map(&:gen_bitable_record))
end

# @param [String] key
# @param [Hash] opts
def update_bitable_by_key(key, opts: nil)
  bitable_json = JSON.parse(`curl -fsSL #{TOS_URL_BASE}/bits-lint/bitable.json`.strip)
  bitable_conf = bitable_json[key]
  bitable_token = bitable_conf&.dig('token')
  bitable_table_id = bitable_conf&.dig('table_id')
  sheet_id = bitable_conf&.dig('sheet_id')

  get_repo = lambda do |os|
    case os
    when 'ios'
      Repo.new(app_id: 137801, name: 'iOS-client')
    when 'android'
      Repo.new(app_id: 116102, name: 'android_client')
    else
      abort("unknown os: #{os}")
    end
  end

  wiki_url =
    if key.start_with?('ios')
      "https://bytedance.feishu.cn/wiki/#{bitable_token}?table=#{bitable_table_id}"
    else
      "https://bytedance.feishu.cn/wiki/LCfYwmusqi7ut9kcj8scLX5DnuH?table=#{bitable_table_id}&sheet=#{sheet_id}"
    end
  puts "即将更新: #{wiki_url}"
  case key
  when /(?<os>ios|android)\/rules/
    os = ($~[:os] || 'Unknown').downcase
    update_all_rule_bitable(repo: get_repo.call(os), bitable_token: bitable_token, bitable_table_id: bitable_table_id)
  when /(?<os>ios|android)\/(?<level>p[0-3])\/rule\/issues/
    level = ($~[:level] || 'Unknown').upcase
    os = ($~[:os] || 'Unknown').downcase
    update_rule_issue_bitable(repo: get_repo.call(os), level: level, token: bitable_token, table_id: bitable_table_id)
  when /(?<os>ios|android)\/(?<level>p[0-3])\/(pod|mod)\/issues/
    os = ($~[:os] || 'Unknown').downcase
    level = ($~[:level] || 'Unknown').upcase
    Bitable.use_user_id = (os == 'android')
    mod_parser_path = opts&.dig('mod_parser_path')
    raise "missing mod parser path" if mod_parser_path.nil? || mod_parser_path.empty?
    raise "missing mod parser at path: #{mod_parser_path}" unless Pathname(mod_parser_path).exist?

    require mod_parser_path
    mod_parser = Parser.new

    update_mod_issue_bitable(
      repo: get_repo.call(os),
      level: level,
      bitable_token: bitable_token,
      bitable_table_id: bitable_table_id,
      mod_parser: mod_parser
    )
  else
    abort('unsupported key')
  end
end

# rubocop:enable Metrics/MethodLength
# rubocop:enable Style/Documentation
