#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'pathname'
require 'net/http'
require_relative '../util/sheet'
require_relative '../util/req'
require_relative './base'

# rubocop:disable Style/Documentation, Metrics/AbcSize, Metrics/MethodLength

class Proj
  attr_accessor :base_metrics, :latest_metrics

  class VersMetrics
    attr_accessor :proj_id, :proj_name, :vers_id, :items

    # @param [Hash] hash
    def initialize(hash)
      @proj_id = hash['id']
      @proj_name = hash['name']
      @vers_id = hash['version']
      raise "parse failed. #{hash}" if @proj_id.nil? || @proj_name.nil? || @vers_id.nil?

      raw_items = (hash&.dig('score')&.dig('dimensions') || []).first&.dig('metrics')
      raise "parse failed. #{raw_items}" if raw_items.nil? || !raw_items.is_a?(Array)

      @items = {}
      raw_items.each do |metric|
        item_name = metric['metricName'] || 'Unknown'
        @items[item_name] = 0 if @items[item_name].nil?
        cnt = (metric['rules']&.dig('details') || []).map { |hash| hash['issueCount'] || 0 }.reduce(:+)
        @items[item_name] += cnt
      end
    end

    def to_s
      "Count: { proj_id: #{proj_id}, proj_name: #{proj_name}, vers_id: #{vers_id}, items: #{items} }"
    end
  end

  class Fetcher # rubocop:disable Style/Documentation
    def base_headers
      {
        'Content-Type' => 'application/json; charset=utf-8',
        'Authorization' => quality_auth_token
      }
    end

    def fetch_latest_group_vers
      uri = URI("#{QUALITY_URL_BASE}/api/group/getGroupVersions?groupName=#{YY_URL_ENCODED_NAME}&qualityConfigId=59")
      req = Net::HTTP::Get.new(uri)
      base_headers.each { |key, val| req[key] = val }
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|  http.request(req) }
      raise "fetch latest group vers failed. res: #{res}" unless res.is_a?(Net::HTTPOK)
      list = JSON.parse(res.body)
      raise "unexpected body: #{list}" unless list.is_a?(Array) && !list.empty?
      list.map { |dict| dict['id'].to_i }.max
    end

    def fetch_q2_diff_group
      uri = URI("#{QUALITY_URL_BASE}/api/group/diffGroup")
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = {
        'groupId' => YY_GROUP_ID,
        'timePeriod' => [
          '2023-04-20T15:59:59.000Z',
          "#{Time.now.strftime("%Y-%m-%d")}T15:59:59.000Z"
        ]
      }.to_json
      base_headers.each { |key, val| req[key] = val }
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|  http.request(req) }
      raise "fetch diff group failed. res: #{res}" unless res.is_a?(Net::HTTPOK)

      JSON.parse(res.body)
    end

    # @param [String | nil] vers_id group version id
    # @return [Array<VersMetrics>]
    def fetch_vers_metrics(vers_id = nil)
      vers_id ||= fetch_latest_group_vers
      uri_str = "#{QUALITY_URL_BASE}/api/group/getGroupAllProjectsWithScore?groupId=#{YY_GROUP_ID}".dup
      uri_str << "&groupVersion=#{vers_id}" unless vers_id.nil?
      uri_str << '&qualityConfigId=59'
      uri = URI(uri_str)
      req = Net::HTTP::Get.new(uri)
      base_headers.each { |key, val| req[key] = val }
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|  http.request(req) }
      raise "fetch diff failed. res: #{res}" unless res.is_a?(Net::HTTPOK)

      list = JSON.parse(res.body)
      raise "unexpected body: #{list}" unless list.is_a?(Array)

      list.map { |hash| VersMetrics.new(hash) }
    end

    # @param [String] proj_id project id
    # @param [String] vers_id version id
    # @param [String | nil] path version id
    def fetch_issue_count(proj_id:, vers_id:, path: nil)
      uri = URI("#{QUALITY_URL_BASE}/api/issue/getProjectIssues")
      params = {
        'operator' => 'gte',
        'order' => '1',
        'status' => 1,
        'pageSize' => 10,
        'pageNum' => 1,
        'projectId' => proj_id,
        'versionId' => vers_id
      }
      params['filePathLike'] = path unless path.nil?
      uri.query = URI.encode_www_form(params)
      req = Net::HTTP::Get.new(uri.request_uri)
      base_headers.each { |key, val| req[key] = val }
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      raise "load failed #{res}" unless res.is_a?(Net::HTTPOK)

      JSON.parse(res.body)&.dig('totalNum')&.to_i || 0
    end
  end
end

class Proj
  class Row
    attr_accessor :proj_name, :base_count, :cur_count, :fix_count, :new_count

    class << self
      # @type [Hash] preferred_owners
      attr_writer :preferred_owners

      def preferred_owners
        @preferred_owners ||= {}
      end

      # @param [Array] rows
      def cache_owner_from_sheet(rows:) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity, Metrics/AbcSize
        rows.each do |row|
          next unless row.is_a?(Array) && row.length > 1

          proj_col = row[0].first
          user_col = row[1].first

          # parse proj name
          next unless proj_col_type = proj_col&.dig('type') || proj_col_type != 'link'

          proj_name = proj_col['link']&.dig('text')
          next if proj_name.nil? || proj_name.empty?

          # parse user
          next unless user_col_type = user_col&.dig('type') || user_col_type != 'mention_user'

          preferred_owners[proj_name] = [user_col]
        end
      end
    end

    # @param [Array<Row>] items
    def self.gen_total(base_count:, cur_count:, fix_count:, new_count:) # rubocop:disable Metrics/AbcSize
      # 总计
      prompt_col = Sheet.gen_text_cell('全部')
      empty_col = Sheet.gen_text_cell('')
      # Q目标数/总目标数
      # 总目标数 = 基准版本问题总数 + 新增问题数
      # Q目标数 = 总目标数 / 2
      total_target_count = base_count + new_count
      q_target_count = (total_target_count.to_f / 2).floor
      ref_cnt_col = [
        Sheet.gen_text_cell(q_target_count.to_s).first,
        Sheet.gen_text_cell('/').first,
        Sheet.gen_text_cell(total_target_count.to_s).first,
      ]
      # 已治理数
      cur_cnt_col = Sheet.gen_value_cell(cur_count)
      # 已治理数
      fix_cnt_col = Sheet.gen_value_cell(fix_count)
      # 新引入数
      new_cnt_col = Sheet.gen_value_cell(new_count)
      # 完成度：已治理数 / Q目标数
      radio = fix_count.to_f / q_target_count
      result_col = Sheet.gen_value_cell("#{(radio * 100).round(2)}")
      [prompt_col, empty_col, ref_cnt_col, cur_cnt_col, fix_cnt_col, new_cnt_col, result_col]
    end

    def self.gen_header
      [
        Sheet.gen_text_cell('项目', bold: true),
        Sheet.gen_text_cell('接口人', bold: true),
        Sheet.gen_text_cell('Q目标数/总目标数', bold: true),
        Sheet.gen_text_cell('当前问题数', bold: true),
        Sheet.gen_text_cell('已治理数', bold: true),
        Sheet.gen_text_cell('新引入数', bold: true),
        Sheet.gen_text_cell('完成度(%)', bold: true)
      ]
    end

    def gen_row
      proj_part = URI.encode_www_form_component(proj_name)
      # 项目
      proj_link = "#{QUALITY_URL_BASE}/project/#{proj_part}"
      proj_col = Sheet.gen_link_cell(text: proj_name, link: proj_link)
      # 接口人
      owner_col = Row.preferred_owners[proj_name] || Sheet.gen_text_cell('')
      # Q目标数/总目标数
      total_target_count = base_count + new_count
      q_target_count = (total_target_count.to_f / 2).floor
      ref_cnt_col = [
        Sheet.gen_text_cell(q_target_count.to_s).first,
        Sheet.gen_text_cell('/').first,
        Sheet.gen_text_cell(total_target_count.to_s).first
      ]
      # 当期数
      cur_cnt_col = Sheet.gen_value_cell(cur_count)
      # 已治理数
      fix_cnt_col = Sheet.gen_value_cell(fix_count)
      # 新引入数
      new_cnt_col = Sheet.gen_value_cell(new_count)
      # 完成度：已治理数 / Q目标数
      radio = fix_count.to_f / q_target_count
      result_col = Sheet.gen_value_cell("#{(radio * 100).round(2)}")
      [proj_col, owner_col, ref_cnt_col, cur_cnt_col, fix_cnt_col, new_cnt_col, result_col]
    end
  end
end

# rubocop:enable Style/Documentation
