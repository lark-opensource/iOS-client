#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../../util/req'
require_relative '../core/base'
require_relative '../core/rule'
require_relative '../core/repo'
require_relative '../core/issue'

RULES = {
  10597 => 'FileRead',    # LarkStorageCheckFileRead
  10598 => 'FileWrite',   # LarkStorageCheckFileWrite
  10599 => 'KeyValue',    # LarkStorageCheckKeyValue
  10601 => 'PathCreate',  # LarkStorageCheckPathCreate
  10602 => 'PathUpdate',  # LarkStorageCheckPathUpdate
  10600 => 'PathAccess',  # LarkStorageCheckPathAccess
}

# dump bits storage issues
# json
# -- file format --
# {
#   "input": {
#     "commit": "commit_id",
#   },
#   "records": [
#     {
#       "path": "Modules/XXX",
#       "start_line": 1,
#       "end_line": 2,
#       "issue": "KeyValue" | "FileRead" | "..."
#     }
#   ]
# }

# @param [String] issue RULES.values
# @return Integer
def to_issue_id(issue)
  RULES.key(issue)
end

# 产生 issues 结果文件，格式如上述
# @param [String] dst_path
def dump_issues(dst_path)
  repo = Repo.new(app_id: 137801, name: 'iOS-client')
  fetcher = Issue::Fetcher.new(app_id: repo.app_id)
  batch_id = Repo::Fetcher.new(app_id: repo.app_id).fetch_latest_batch_id
  issues = fetcher.fetch_issues_by_rules(ids: RULES.keys, batch_id: batch_id)
  raise 'issues should be empty' if issues.empty?

  file_ignore_checkers = {}

  commit_id = issues.first.raw['commit_id']
  obj = {
    'commit' => commit_id,
    'issues' => issues.map do |issue|
      next nil if issue.path.start_with?('Pods/')

      start_line = issue.raw['valid_start_line']
      end_line = issue.raw['valid_end_line']

      {
        'path' => issue.path,
        'start_line' => start_line,
        'end_line' => end_line,
        'issue' => RULES[issue.rule.id]
      }
    end.compact
  }
  File.open(dst_path, 'w') do |file|
    file.write(JSON.pretty_generate(obj))
  end
end

if __FILE__  == $0
  require 'tmpdir'
  require 'pathname'

  tmp_path = Pathname(Dir.mktmpdir).join('issues.json')
  dump_issues(tmp_path.to_s)
  puts "dump bits issues to #{tmp_path}"
end
