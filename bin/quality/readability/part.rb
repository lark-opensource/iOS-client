#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'pathname'
require_relative './base'
require_relative '../util/sheet'

class Part # rubocop:disable Style/Documentation
  class Proj
    attr_accessor :id, :name, :path, :base_vers_id, :latest_vers_id
  end

  attr_accessor :key, :path, :proj, :base_issue_count, :latest_issue_count, :owners

  class << self
    # 用于获取对应的 owner
    # @type [Proc] default_owner_for_key，输入 key，返回 [user_id, user_name]
    attr_accessor :default_owner_for_key

    # @type [Hash] preferred_owners
    attr_writer :preferred_owners

    def preferred_owners
      @preferred_owners ||= {}
    end

    def key_field_name
      'Key'
    end

    # @param [Array] rows
    def cache_owner_from_sheet(rows:) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity, Metrics/AbcSize
      rows.each do |row|
        next unless row.is_a?(Array) && row.length > 1

        key_col = row[0].first
        user_col = row[1].first

        # parse mod name
        next unless key_col_type = key_col&.dig('type') || key_col_type != 'link'

        key = key_col['link']&.dig('text')
        next if key.nil? || key.empty?

        # parse user
        next unless user_col_type = user_col&.dig('type') || user_col_type != 'mention_user'

        preferred_owners[key] = [user_col]
      end
    end

    def gen_header
      [
        Sheet.gen_text_cell(self.key_field_name, bold: true),
        Sheet.gen_text_cell('责任人', bold: true),
        Sheet.gen_text_cell('基准问题数', bold: true),
        Sheet.gen_text_cell('当前问题数', bold: true),
        Sheet.gen_text_cell('完成度(%)', bold: true)
      ]
    end

    # @param [Integer] base_count
    # @param [Integer] latest_count
    def gen_total_row(base_count:, latest_count:) # rubocop:disable Metrics/AbcSize
      # 总计
      prompt_col = Sheet.gen_text_cell('总计')
      empty_col = Sheet.gen_text_cell('')
      # 基准问题数
      base_cnt_col = Sheet.gen_value_cell(base_count)
      # 当前问题数
      cur_cnt_col = Sheet.gen_value_cell(latest_count)
      # 完成度
      radio = (base_count - latest_count).to_f * 2 / [1, base_count].max
      result_col = Sheet.gen_value_cell("#{(radio * 100).round(1)}")
      [prompt_col, empty_col, base_cnt_col, cur_cnt_col, result_col]
    end
  end

  def gen_row # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    module_part = URI.encode_www_form_component(proj.name)
    path_part = URI.encode_www_form_component(path)
    vers_part = proj.latest_vers_id
    # Key
    key_link = "#{QUALITY_URL_BASE}/project/#{module_part}/issue-detail?projectVersion=#{vers_part}&filePathLike=#{path_part}&pageNum=1&status=1"
    key_col = Sheet.gen_link_cell(text: key, link: key_link)
    # 责任人
    owner_col =
      if owner = owners&.first
        [owner]
      elsif preferred_owner = Part.preferred_owners[key]
        preferred_owner
      elsif default_owner = Part.default_owner_for_key.call(key)
        Sheet.gen_user_cell(id: default_owner[0], name: default_owner[1])
      else
        Sheet.gen_text_cell('')
      end
    # 初始问题数
    base_cnt_col = Sheet.gen_value_cell(base_issue_count)
    # 当前问题数
    cur_cnt_col = Sheet.gen_value_cell(latest_issue_count)
    # 完成度
    radio = (base_issue_count - latest_issue_count).to_f * 2 / [1, base_issue_count].max
    result_col = Sheet.gen_value_cell("#{(radio * 100).round(1)}")
    [key_col, owner_col, base_cnt_col, cur_cnt_col, result_col]
  end
end
