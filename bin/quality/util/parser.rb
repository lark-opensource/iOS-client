#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require_relative '../../pod/wiki_pod'

class Parser
  # @type [Pathname] repo_path
  attr_accessor :repo_path

  def repo_path
    @repo_path ||= Pathname(`git rev-parse --show-toplevel`.chomp)
  end

  # @param [String] file_path 相对于 `repo_path` 的相对路径
  # @return [Array<String>], [0] - mod name, [1] - mod path relative to repo_path
  def find_mod(file_path)
    return if file_path.nil? || file_path.empty?

    test_dir = Pathname(repo_path).join(file_path).parent
    while test_dir.exist? && test_dir.directory? && test_dir.to_s.length > repo_path.to_s.length
      matched = Dir.entries(test_dir).detect { |e| e.end_with?('.podspec') }
      if matched
        pod_name = matched.gsub('.podspec', '')
        pod_path = begin
                     test_dir.relative_path_from(repo_path).to_s
                   rescue
                     nil
                   end
        return [pod_name, pod_path]
      end

      test_dir = test_dir.parent
    end
  end

  def wiki_pods
    @wiki_pods ||=
      begin
        wiki_pods = WikiPod.load_from_server
        ret = {}
        wiki_pods.each { |pod| ret[pod.name] = pod }
        ret
      end
  end

  # get owners by mod name
  # @param [String] mod_name
  # @return [Hash] [{ "id" => user_id }]
  # @return [Array] [{ "email" => user_email }]
  def owners_for_mod(mod_name)
    wiki_pods[mod_name]&.owners&.map(&:to_bitable_field) || []
  end

  # get biz name by mod name
  # @return [String | nil]
  def biz_for_mod(mod_name)
    wiki_pods[mod_name]&.biz
  end
end
