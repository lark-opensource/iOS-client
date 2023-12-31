#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'pathname'
require 'net/http'
require_relative './req'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Style/Documentation, Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

# Bitable
class Bitable

  class << self
    # see more: https://open.feishu.cn/document/server-docs/docs/bitable-v1/app-table-record/create
    attr_accessor :use_user_id
  end

  attr_accessor :token, :table_id

  def initialize(token:, table_id:)
    @token = token
    @table_id = table_id
  end

  # @return [Array<Hash>]
  def load_records(recursive: true, page_token: nil, field_names: nil)
    # build uri
    uri_str = "https://open.feishu.cn/open-apis/bitable/v1/apps/#{token}/tables/#{table_id}/records".dup
    uri_str << '?user_id_type=user_id' if Bitable.use_user_id
    uri = URI(uri_str)
    # attach params
    params = { page_size: 500 }
    params['page_token'] = page_token unless page_token.nil?
    params['field_names'] = field_names unless field_names.nil?
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri).json!.auth!
    body = req.send
    data = body['data'] || {}
    has_more = data&.dig('has_more') || false
    items = (data&.dig('items') || [])
    page_token = data&.dig('page_token')
    if has_more && recursive
      load_records(page_token: page_token, field_names: field_names) + items
    else
      items
    end
  end

  # @type [Array<String] ids 要删除的 record ids
  # @type [Integer] index index for logging
  def delete_records(ids:, index:)
    # build uri
    uri = URI("https://open.feishu.cn/open-apis/bitable/v1/apps/#{token}/tables/#{table_id}/records/batch_delete")
    req = Net::HTTP::Post.new(uri).json!.auth!
    req.body = { 'records' => ids }.to_json
    puts "    begin delete records at #{index}..<#{index + ids.length}"
    res = req.send
    puts "    end delete records at #{index}..<#{index + ids.length}"
  end

  # @return [Boolean] has_more 是否还有要清理的
  def clean_records
    index = 0
    ids = load_records(recursive: false).map { |item| item['record_id'] }.compact
    until ids.empty?
      delete_records(ids: ids, index: index)
      index += ids.length
      ids = load_records(recursive: false).map { |item| item['record_id'] }.compact
    end
  end

  # @param [Array<Hash>] records
  def upload(records:)
    index = 0
    step = 500
    do_insert = lambda do
      uri_str = "https://open.feishu.cn/open-apis/bitable/v1/apps/#{token}/tables/#{table_id}/records/batch_create".dup
      uri_str << '?user_id_type=user_id' if Bitable.use_user_id
      uri = URI(uri_str)
      req = Net::HTTP::Post.new(uri).json!.auth!
      slice = records.slice(index, step)
      slice_len = slice.length
      req.body = { 'records' => slice }.to_json
      puts "    begin insert records at #{index}..<#{index + slice_len}"
      res = req.send
      puts "    end insert records at #{index}..<#{index + slice_len}"
      index += step
    end
    do_insert.call while index < records.count
  end
end

# rubocop:enable all
