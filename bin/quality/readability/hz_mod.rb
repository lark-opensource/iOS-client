#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative './part'
require_relative './mod'
require_relative './proj'
require_relative '../util/sheet'
require_relative '../../pod/wiki_pod'

# key: proj name, value - relative path
ANDROID_PROJ_PATH = {
  'android/platform' => 'modules/platform',
  'android/biz/core' => 'modules/biz/core',
  'android/biz/im' => 'modules/biz/im'
}.freeze

# 属杭州
class HZAndroidConf
  SHEET_TOKEN = 'QwmNsaoQthCDGbtwg9ScbuqRnPe'
  SHEET_ID = 'WqIbUF'
  attr_accessor :path, :owners

  def proj_name
    @proj_name ||= find_proj_name(path)
  end

  # @type [String] path
  # @return [String | nil]
  def find_proj_name(path)
    ANDROID_PROJ_PATH.each do |proj_name, proj_path|
      return proj_name if path.start_with?(proj_path)
    end
    nil
  end

  # @param [Array<Hash>] rows
  # @return [Array<HZAndroidConf>]
  def self.load_from_sheet
    # https://bytedance.feishu.cn/wiki/UuVcwCt6tiecIMkIn0HcKWDbnae?sheet=WqIbUF
    sheet_token = 'QwmNsaoQthCDGbtwg9ScbuqRnPe'
    sheet_id = 'WqIbUF'
    sheet = Sheet.new(token: sheet_token, sheet_id: sheet_id)
    row_count = sheet.row_count
    # cache exists module-user
    item_from_index = 3
    return [] unless row_count >= item_from_index

    range = "#{sheet_id}!A#{item_from_index}:B#{row_count}"
    module_rows = sheet.get_ranges([range]).first do |dict|
      dict.is_a?(Hash) && (dict['range'] || '') == range
    end['values']

    conf_arr = module_rows.map do |row|
      next unless row.is_a?(Array) && row.length > 1

      # @type [Array] path_col
      # @type [Array] user_col
      path_col = row[0]
      user_col = row[1]
      raise 'unexpected row' unless path_col.is_a?(Array) && user_col.is_a?(Array)

      # parse path
      # @type [Array] path_list path list
      path_list = path_col.map do |hash|
        next [] unless hash.is_a?(Hash) && !hash['type'].nil? && hash['type'] == 'text'
        text = hash['text']&.dig('text')
        next [] if text.nil? || text.empty?
        text.lines.map(&:chomp).filter { |line| !line.empty? }
      end.flatten
      # next if path_list.empty?
      raise 'path_list is empty' if path_list.empty?

      # parse owners
      owners = user_col.filter_map do |hash|
        next unless hash.is_a?(Hash) && !hash['type'].nil? && hash['type'] == 'mention_user'
        hash
      end
      path_list.map do |path|
        conf = HZAndroidConf.new
        conf.path = path
        conf.owners = owners
        conf
      end
    end.flatten

    conf_arr
  end
end
