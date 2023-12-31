#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './rule'

# 问题
class Issue
  # @type [String] path
  # @type [Rule] rule
  attr_accessor :path, :rule, :raw

  def to_s
    "{ path: #{path}, rule: #{rule} }"
  end
end

class Issue
  class Fetcher
    attr_accessor :app_id

    def initialize(app_id:)
      @app_id = app_id
    end

    # 获取问题数量
    # @param [Integer] batch_id
    # @param [Hash] search
    # @return [Integer]
    def _fetch_issue_count(batch_id:, search:)
      uri = URI("#{API_URL_BASE}/improve/issue_list_batch")
      req = Net::HTTP::Post.new(uri).json!.auth!
      req['cookie'] = API_COOKIE_VALUE
      req.body = {
        'app_id' => app_id,
        'batch_id' => batch_id,
        'page_num' => 1,
        'page_size' => 10,
        'from_type' => 'all',
        'search' => search
      }.to_json
      data = (req.send)['data']
      raise "unexpected response. data: #{data}" unless data.is_a?(Hash)

      count = data['count']
      raise "unexpected response. data: #{data}" unless count.is_a?(Integer)
      count
    end

    # 获取指定 rule 的问题数量
    # @param [Rule] rule
    # @param [Integer] batch_id
    # @return [Integer]
    def fetch_issue_count_by_rule(rule, batch_id:)
      _fetch_issue_count(batch_id: batch_id, search: { 'rule_ids' => [rule.id] })
    end

    # 获取指定 level 的问题数量
    # @param [String] level
    # @param [Integer] batch_id
    # @return [Integer]
    def fetch_issue_count_by_level(level, batch_id:)
      _fetch_issue_count(batch_id: batch_id, search: { 'rule_levels' => [level] })
    end

    # 获取问题
    # @param [Integer | nil] batch_id
    # @param [Hash] search_params
    # @param [Integer] start_page
    # @return [Array<Issue>]
    def _search_issues_(batch_id:, start_page: 1, search_params:)
      page_size = 1_000
      uri = URI("#{API_URL_BASE}/improve/issue_list_batch")
      req = Net::HTTP::Post.new(uri).json!.auth!
      req['cookie'] = API_COOKIE_VALUE
      req.body = {
        'app_id' => app_id,
        'batch_id' => batch_id,
        'page_num' => start_page,
        'page_size' => page_size,
        'from_type' => 'all',
        'search' => search_params
      }.to_json
      data = (req.send)['data']
      raise "unexpected response. data: #{data}" unless data.is_a?(Hash)
      # @type [Integer] count
      # @type [Array<Hash>] raw_issues
      count = data['count']
      raw_issues = data['issues']
      raise "unexpected response. data: #{data}" unless count.is_a?(Integer) && raw_issues.is_a?(Array)

      issues = raw_issues.map do |raw|
        issue = Issue.new
        issue.path = raw['path']
        rule = Rule.new
        rule.id = raw['rule_id']
        rule.name = raw['rule_name']
        rule.level = raw['level']
        rule.engine = raw['engine']
        issue.rule = rule
        issue.raw = raw
        issue
      end
      has_more = count > page_size * start_page
      if has_more
        issues + _search_issues_(batch_id: batch_id, start_page: start_page + 1, search_params: search_params)
      else
        issues
      end
    end

    # 获取问题
    # @param [Array<String>] levels
    # @param [Integer] batch_id
    # @return [Array<Issue>]
    def fetch_issues_by_levels(levels, batch_id:)
      _search_issues_(batch_id: batch_id, start_page: 1, search_params: { 'rule_levels' => levels })
    end

    def fetch_issues_by_rules(ids:, batch_id:)
      _search_issues_(batch_id: batch_id, start_page: 1, search_params: { 'rule_ids' => ids })
    end
  end
end
