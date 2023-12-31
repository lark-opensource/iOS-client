#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'pathname'
require 'net/http'
require_relative './req'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Style/Documentation

# Sheet
class Sheet
  attr_accessor :token, :sheet_id

  def initialize(token:, sheet_id:)
    @token = token
    @sheet_id = sheet_id
  end

  def fetch_meta
    uri = URI("https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/#{token}/metainfo")
    req = Net::HTTP::Get.new(uri).json!.auth!
    body = req.send
    body
  end

  # 获取最大行数
  # @return [Integer]
  def row_count
    uri = URI("https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/#{token}/sheets/#{sheet_id}")
    req = Net::HTTP::Get.new(uri).json!.auth!
    body = req.send
    body['data']&.dig('sheet')&.dig('grid_properties')&.dig('row_count')
  end

  # @param [Integer] start_index
  # @param [Integer] end_index
  def remove_rows(start_index:, end_index: nil) # rubocop:disable Metrics/MethodLength
    end_index ||= row_count
    return unless end_index >= start_index

    uri = URI("https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/#{token}/dimension_range")
    req = Net::HTTP::Delete.new(uri).json!.auth!
    req.body = {
      'dimension' => {
        'sheetId' => sheet_id,
        'majorDimension' => 'ROWS',
        'startIndex' => start_index,
        'endIndex' => end_index
      }
    }.to_json
    body = req.send
    puts "delete succeed. row count: #{body['data']&.dig('delCount')}"
  end

  # @param [Array] rows
  # @param [Integer] index
  def insert(rows:, index:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    return if rows.empty?

    range_label1 = 'A'
    range_label2 = range_label1
    (rows.first.count - 1).times { range_label2 = range_label2.next }

    slice_index = 0
    slice_step = 50
    row_index = index
    # https://open.feishu.cn/document/ukTMukTMukTM/uUDN04SN0QjL1QDN/sheets-v3/spreadsheet-sheet-value/insert
    do_insert = lambda do
      slice = rows.slice(slice_index, slice_step)
      range = "#{sheet_id}!#{range_label1}#{row_index}:#{range_label2}#{row_index + slice.length - 1}"
      uri = URI("https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/#{token}/sheets/#{sheet_id}/values/#{range}/insert")
      req = Net::HTTP::Post.new(uri).json!.auth!(refresh: true) # 该接口可能会报 auth 错误，重新拉一下 token 可以解决
      req.body = { 'values' => slice }.to_json
      req.send
      puts "insert succeed. count #{slice.count}"

      row_index += slice.length
      slice_index += slice_step
    end
    do_insert.call while slice_index < rows.count
  end

  # @param [Array] ranges
  # @return [Hash]
  def get_ranges(ranges)
    # ref: https://open.feishu.cn/document/ukTMukTMukTM/uUDN04SN0QjL1QDN/sheets-v3/spreadsheet-sheet-value/batch_get
    uri = URI("https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/#{token}/sheets/#{sheet_id}/values/batch_get")
    req = Net::HTTP::Post.new(uri).json!.auth!
    req.body = { 'ranges' => ranges }.to_json
    body = req.send
    body['data']&.dig('value_ranges') || []
  end
end

class Sheet
  # 产生文本单元格
  # @param [String] text
  def self.gen_text_cell(text, bold: false)
    [
      {
        'type' => 'text',
        'text' => {
          'text' => text,
          'segment_style' => {
            'style' => {
              'bold' => bold
            },
            'affected_text' => text
          }
        }
      }
    ]
  end

  # 产生数值单元格
  # @param [Numeric | String] value
  def self.gen_value_cell(value)
    [
      {
        'type' => 'value',
        'value' => {
          'value' => value.to_s
        }
      }
    ]
  end

  # 产生链接单元格
  def self.gen_link_cell(text:, link:)
    [
      {
        'type' => 'link',
        'link' => {
          'text' => text,
          'link' => link
        }
      }
    ]
  end

  # 产生 at 类型的单元格
  def self.gen_user_cell(id:, name:, notify: false)
    [
      {
        'type' => 'mention_user',
        'mention_user' => {
          'name' => name,
          'user_id' => id,
          'notify' => notify
        }
      }
    ]
  end
end

# rubocop: enable all
