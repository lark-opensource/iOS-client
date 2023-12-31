#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'tmpdir'
require_relative './dump_bits_issue'
require_relative '../../util/parser'
require_relative '../../../pod/wiki_pod'

class IssueItem
  attr_accessor :raw, :pod, :commit_id

  # @param [Hash] raw { :path, :start_line, :end_line, :issue } see more: './storage/dump_bits_issue.rb'
  # @param [WikiPod] pod
  def initialize(raw:, pod:, commit_id:)
    @raw = raw
    @pod = pod
    @commit_id = commit_id
  end

  REPO_BLOB_BASE = "https://code.byted.org/lark/iOS-client/blob"

  def gen_file_link
    line_fragment = raw['start_line'].to_s
    line_fragment << "-#{raw['end_line']}" unless raw['end_line'].nil?

    "#{REPO_BLOB_BASE}/#{commit_id}/#{raw['path']}#L#{line_fragment}"
  end

  def gen_bitable_record
    fields = {}
    fields['文件'] = { 'text': raw['path'], 'link': gen_file_link }
    fields['问题类型'] = raw['issue']
    fields['所属组件'] = pod.name
    fields['所属业务'] = pod.biz
    owner = pod&.owners&.first
    fields['责任人'] = [owner.to_bitable_field] unless owner.nil?
    { 'fields': fields }
  end
end

# 1. fetch issues from bits
tmp_path = Dir.mktmpdir + "/issues.json"
dump_issues(tmp_path)
json = JSON.parse(File.read(tmp_path))
commit_id = json['commit']
issues = json['issues']

# 2. upload records to bitable
pod_parser = Parser.new
wiki_pods = WikiPod.load_from_server.group_by(&:name).transform_values { |v| v.first }
records = issues.filter_map do |raw|
  path = raw['path']
  next nil unless path.start_with?('Modules/')

  arr = pod_parser.find_mod(path)
  next nil if arr.nil?
  pod_name = arr[0]
  wiki_pod = wiki_pods[pod_name]
  next nil if wiki_pod.nil?

  IssueItem.new(raw: raw, pod: wiki_pod, commit_id: commit_id).gen_bitable_record
end

puts "更新 https://bytedance.feishu.cn/base/WmS6bHxjVaPjRisAjdOcIGcnnbg?table=tbl3uhnx3pmYLPDZ"
bitable = Bitable.new(token: 'WmS6bHxjVaPjRisAjdOcIGcnnbg', table_id: 'tbl3uhnx3pmYLPDZ')
bitable.clean_records
bitable.upload(records: records)
