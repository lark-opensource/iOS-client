#!/usr/bin/env ruby
# frozen_string_literal: true

require 'set'
require_relative '../util/sheet'

# @param [String] sheet_token
# @param [String] sheet_id
# @return [Array<String>] user_ids
def load_hz_ios_developers(sheet_token:, sheet_id:)
  sheet = Sheet.new(token: sheet_token, sheet_id: sheet_id)
  range = "#{sheet_id}!A3:B#{sheet.row_count}"
  rows = sheet.get_ranges([range]).first do |dict|
    dict.is_a?(Hash) && (dict['range'] || '') == range
  end['values']

  rows.filter_map do |row|
    next unless row.is_a?(Array) && row.length > 1
    user_col = row[0]
    city_col = row[1]
    raise 'unexpected row' unless user_col.is_a?(Array) && city_col.is_a?(Array)
    next if user_col.empty? || city_col.empty?

    next if city_col.first['type'].nil? || city_col.first['type'] != 'text'
    city_name = city_col.first['text']&.dig('text')&.chomp
    next if city_name.nil? || city_name.empty? || city_name != '杭州'

    next if user_col.first['type'].nil? || user_col.first['type'] != 'mention_user'
    user_id = user_col.first['mention_user']&.dig('user_id')
    next if user_id.nil? || user_id.empty?
    user_id
  end
end

# @param [Array<String>] user_ids
# @param [Array<String>] sheet_token
# @param [Array<String>] sheet_id
# @return [Array<Hash>] rows
def filter_hz_pods_by_user(user_ids:, sheet_token:, sheet_id:)
  hz_user_ids = user_ids.to_set

  sheet = Sheet.new(token: sheet_token, sheet_id: sheet_id)
  row_count = sheet.row_count
  return [] unless row_count >= 5

  range = "#{sheet_id}!A5:E#{row_count}"
  rows = sheet.get_ranges([range]).first do |dict|
    dict.is_a?(Hash) && (dict['range'] || '') == range
  end['values']

  rows.filter do |row|
    next false unless row.is_a?(Array) && row.length > 1
    user_col = row[1]
    raise 'unexpected row' unless user_col.is_a?(Array)
    next false if user_col.empty?

    next false if user_col.first['type'].nil? || user_col.first['type'] != 'mention_user'
    user_id = user_col.first['mention_user']&.dig('user_id')
    next false if user_id.nil? || user_id.empty?

    hz_user_ids.include? user_id
  end
end

