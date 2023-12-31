#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'pathname'
require 'net/http'
require_relative './proj'
require_relative './part'
require_relative './part+fetch'
require_relative './pod'
require_relative '../../pod/wiki_pod'

# rubocop:disable Metrics

Q2_SHEET_TOKEN = 'QwmNsaoQthCDGbtwg9ScbuqRnPe'
# https://lark-code-quality.bytedance.net/group/25/overview?groupVersion=903
Q2_BASE_GROUP_VERS_ID = '903'
Q2_PROJECTS = %w[
  Modules/Foundation
  Modules/Infra
  Modules/Messenger
  Modules/SpaceKit
  Modules/Todo
  Modules/Universe
  Modules/ByteWebImage
  android/component
  android/platform
  android/assembly
  android/biz/im
  android/biz/core
  android/biz/ccm
  android/biz/todo
].freeze
# ttnet/MultiProcessSharedProvider

AVAILABLE_PROJ_SHEET_IDS = {
  'Modules/Foundation' => '93242c',
  'Modules/Infra' => 'FPECa9',
  'Modules/Messenger' => 'LbHcad'
}.freeze

@wiki_pod_map = nil
Part.default_owner_for_key = lambda do |pod_name|
  @wiki_pod_map ||= WikiPod.load_from_server.group_by(&:name)
  return unless wiki_pod = @wiki_pod_map[pod_name]&.first
  # @type [WikiPod.User] owner
  return unless owner = wiki_pod.owners&.first

  [owner.id, owner.name]
end

FIXED_ROW_COUNT = 2 # sheet 里前两行是固定的
PROJ_ITEM_FROM_INDEX = FIXED_ROW_COUNT + 2 + 1 # 从第 5 行开始是 proj 信息
PART_ITEM_FROM_INDEX = FIXED_ROW_COUNT + 2 + 1 # 从第 5 行开始是 pod 信息

def update_all_projs
  fetcher = Proj::Fetcher.new
  body = fetcher.fetch_q2_diff_group

  sheet_id = 'ZHnoWg'
  sheet = Sheet.new(token: Q2_SHEET_TOKEN, sheet_id: sheet_id)
  row_count = sheet.row_count
  if row_count > FIXED_ROW_COUNT
    # cache exists module-user
    if row_count >= PROJ_ITEM_FROM_INDEX
      range = "#{sheet_id}!A#{PROJ_ITEM_FROM_INDEX}:B#{row_count}"
      proj_user_rows = sheet.get_ranges([range]).first do |dict|
        dict.is_a?(Hash) && (dict['range'] || '') == range
      end['values']
      Proj::Row.cache_owner_from_sheet(rows: proj_user_rows)
    end
  end

  rows = []
  rows << Proj::Row.gen_total(
    base_count: body['totalInitIssueCount'],
    cur_count: body['totalCurrentIssuesCount'],
    fix_count: body['totalFixedIssueCount'],
    new_count: body['totalNumberOfNewIssues']
  )
  rows << Proj::Row.gen_header

  proj_list_raw = body['issueDetail']
  rows += Q2_PROJECTS.map do |proj_name|
    raw = proj_list_raw.find { |raw| raw['projectName'] == proj_name }
    next nil if raw.nil?

    row = Proj::Row.new
    row.proj_name = proj_name
    row.base_count = raw['baseIssueCount']
    row.cur_count = raw['currentIssueCount']
    row.fix_count = raw['fixedIssueCount']
    row.new_count = raw['numberOfNewIssues']
    row.gen_row
  end.compact

  sheet.remove_rows(start_index: FIXED_ROW_COUNT + 1, end_index: row_count) if row_count > FIXED_ROW_COUNT
  sheet.insert(rows: rows, index: FIXED_ROW_COUNT + 1)
end

def update_sheet_type2(sheet_id:)
  sheet = Sheet.new(token: Q2_SHEET_TOKEN, sheet_id: sheet_id)
  row_count = sheet.row_count
  if row_count > FIXED_ROW_COUNT
    # cache exists users
    if row_count >= PART_ITEM_FROM_INDEX
      range = "#{sheet_id}!A#{PART_ITEM_FROM_INDEX}:B#{row_count}"
      user_rows = sheet.get_ranges([range]).first do |dict|
        dict.is_a?(Hash) && (dict['range'] || '') == range
      end['values']
      Part.cache_owner_from_sheet(rows: user_rows)
    end
  end

  rows = yield
  sheet.remove_rows(start_index: FIXED_ROW_COUNT + 1, end_index: row_count) if row_count > FIXED_ROW_COUNT
  sheet.insert(rows: rows, index: FIXED_ROW_COUNT + 1)
end

# @param [String] repo_path repo 根路径，用于根据 file_path 找到 pod
# @param [String] proj_name 模块，可选值：'Modules/Foundation' | 'Modules/Infra' | 'Modules/Messenger'
def update_proj_pods(proj_name:, repo_path:)
  raise "unsupported module: #{proj_name}" unless sheet_id = AVAILABLE_PROJ_SHEET_IDS[proj_name]

  proj = Part::Proj.load_by_name(proj_name, Q2_BASE_GROUP_VERS_ID)
  raise "unsupported project: #{proj_name}" if proj.nil?

  original_pods = Pod.list_all(proj: proj, repo_path: repo_path)
  pods = original_pods.filter_map do |pod|
    pod.update_latest_issue_count!
    next if pod.latest_issue_count.zero?

    pod.update_base_issue_count!
  end.sort_by do |pod| # rubocop: disable Style/MultilineBlockChain
    -pod.latest_issue_count
  end

  update_sheet_type2(sheet_id: sheet_id) do
    fetcher = Proj::Fetcher.new
    rows = [
      Pod.gen_total_row(
        base_count: fetcher.fetch_issue_count(proj_id: proj.id, vers_id: proj.base_vers_id),
        latest_count: fetcher.fetch_issue_count(proj_id: proj.id, vers_id: proj.latest_vers_id)
      ),
      Pod.gen_header
    ]
    rows.concat pods.map(&:gen_row)
    rows
  end
end

def update_hz_pods
  require_relative './hz_pod'

  user_ids =load_hz_ios_developers(sheet_token: Q2_SHEET_TOKEN, sheet_id: 'It77Wi')
  infra_rows = filter_hz_pods_by_user(user_ids: user_ids, sheet_token: Q2_SHEET_TOKEN, sheet_id: 'FPECa9')
  messenger_rows = filter_hz_pods_by_user(user_ids: user_ids, sheet_token: Q2_SHEET_TOKEN, sheet_id: 'LbHcad')

  # @type [Array] row
  # @type [Integer] col_index
  # @return [Integer]
  cnt_map = lambda do |row, col_index|
    return 0 unless row.is_a?(Array) && row.length > col_index
    cell = row[col_index]
    return 0 unless !cell.nil? && cell.is_a?(Array) && !cell.empty?
    return cell.first['value']&.dig('value')&.to_i || 0
  end
  rows = infra_rows + messenger_rows
  rows.sort_by! { |row| -cnt_map.call(row, 3) }
  total_base_cnt = rows.map { |row| cnt_map.call(row, 2) }.reduce(:+)
  total_latest_cnt = rows.map { |row| cnt_map.call(row, 3) }.reduce(:+)

  update_sheet_type2(sheet_id: 'xWvghJ') do
    [
      Pod.gen_total_row(base_count: total_base_cnt, latest_count: total_latest_cnt),
      Pod.gen_header
    ] + rows
  end
end

# Update hangzhou android mod
def update_hz_mods
  require_relative './hz_mod'
  confs = HZAndroidConf.load_from_sheet
  # @type [Hash<String, Part::Proj>] projs key: proj_name
  proj_map = Part::Proj
               .load_by_names(ANDROID_PROJ_PATH.keys, Q2_BASE_GROUP_VERS_ID)
               .group_by(&:name)
               .transform_values { |v| v.first }

  # @type [Array<Mod>] mods
  mods = confs.filter_map do |conf|
    next if conf.proj_name.nil?
    next unless proj = proj_map[conf.proj_name]

    mod = Mod.new
    mod.key = conf.path
    mod.path = conf.path
    mod.proj = proj
    mod.owners = conf.owners
    mod.update_base_issue_count!
    mod.update_latest_issue_count!
    mod
  end.sort_by do |mod| # rubocop: disable Style/MultilineBlockChain
    -mod.latest_issue_count
  end

  update_sheet_type2(sheet_id: 'Xx7mgE') do
    rows = [
      Mod.gen_total_row(
        base_count: mods.map(&:base_issue_count).reduce(:+),
        latest_count: mods.map(&:latest_issue_count).reduce(:+)
      ),
      Mod.gen_header
    ]
    rows.concat mods.map(&:gen_row)
    rows
  end
end

# rubocop:enable all
