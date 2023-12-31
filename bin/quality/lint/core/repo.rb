#!/usr/bin/env ruby
# frozen_string_literal: true

# 仓库
class Repo
  attr_accessor :app_id, :name

  # @param [Integer] app_id
  # @param [String] name
  def initialize(app_id:, name:)
    @app_id = app_id
    @name = name
  end
end

class Repo
  require 'time'
  require_relative './base'
  require_relative '../../util/req'

  class Fetcher
    attr_accessor :app_id

    def initialize(app_id:)
      @app_id = app_id
    end

    # 获取最新的 batch_id
    # @param [Array<Integer>] ignored 需要忽略的 batch_ids（有些可能有问题）
    # @return [String]
    def fetch_latest_batch_id(ignored: [])
      uri = URI("#{API_URL_BASE}/improve/list_timestamp")
      req = Net::HTTP::Post.new(uri).json!.auth!
      req['cookie'] = API_COOKIE_VALUE
      cur_ts = Time.new.to_i
      req.body = {
        'app_id' => app_id,
        'start_time' => cur_ts - 3600 * 24 * 7, # 向后搜 7 天
        'end_time' => cur_ts
      }.to_json
      data = (req.send)['data']
      # @type [Array<Hash>] timestamps
      timestamps = data&.dig('timestamps')
      raise "unexpected response: #{timestamps}" unless timestamps.is_a?(Array)

      # 预期的 timestamp 结构：{ 'job_status' => 'success' | 'failure', 'timestamp' => 123, 'batch_id' => 456 }
      timestamps
        .filter { |h| h['job_status'] == 'success' && !ignored.include?(h['batch_id']) }
        .sort_by { |h| h['timestamp'] }
        .map { |h| h['batch_id'] }
        .last
    end
  end
end
