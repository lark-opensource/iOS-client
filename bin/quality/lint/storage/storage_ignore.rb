#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'

module IgnoreCmd
  TYPE_BASE = 'lint:'
  module Types
    NEXT = "disable:next"
    THIS = "disable:this"
    MULTI_BEG = 'disable'
    MULTI_END = 'enable'

    def self.all
      [NEXT, THIS, MULTI_BEG, MULTI_END]
    end

    # @param [String] line
    # @param [String] rule_name
    # @return [IgnoreCmd::Types | nil]
    def self.parse_type(line, rule_name)
      line = line.chomp
      return if line.empty?

      matches = /\/\/(\s)+#{TYPE_BASE}(?<cmd>[\w:]+)\s(?<rule_names>[\s\w\d,]+)/.match(line)
      return unless matches

      cmd = matches[:cmd]&.chomp
      rule_name_str = matches[:rule_names]&.chomp
      return if cmd.nil? || cmd.empty? || rule_name_str.nil? || rule_name_str.empty?

      rule_names = rule_name_str.split(',').map(&:strip)
      return unless Types.all.include?(cmd) && rule_names.include?(rule_name)
      cmd
    end
  end

  class LineRange
    attr_accessor :begin, :end

    # @param [Integer] begin_num
    # @param [Integer] end_num
    def initialize(begin_num, end_num)
      @begin = begin_num
      @end = end_num
    end
  end

  # @return [String] file_path
  # @return [String] rule_name
  # @return [Array<[LineRange]>]
  def self.parse_ranges(file_path, rule_name)
    # @type [Pathname] path
    path = Pathname.new(file_path)
    return [] unless path.exist?

    ret = []
    multi_cmds = []
    last_num = 1
    File.foreach(path).with_index do |line, line_num|
      num = line_num + 1  # from 0
      last_num = num
      type = IgnoreCmd::Types.parse_type(line, rule_name)
      next if type.nil?

      case type
      when Types::NEXT
        ret << LineRange.new(num, num + 1)
      when Types::THIS
        ret << LineRange.new(num, num)
      when Types::MULTI_BEG, Types::MULTI_END
        multi_cmds << [num, type]
      end
    end
    return ret if multi_cmds.empty?

    # @type [[Integer, String]] stack
    stack = []
    multi_cmds.each do |cmd|
      cmd_line = cmd[0]
      cmd_type = cmd[1]
      case cmd_type
      when Types::MULTI_BEG
        stack << cmd
      when Types::MULTI_END
        begin_cmd = stack.pop
        raise "unexpected command. cmds: #{multi_cmds}, file_path: #{file_path}" if begin_cmd.nil?
        ret << LineRange.new(begin_cmd[0], cmd_line)
      end
    end
    unless stack.empty?
      begin_cmd = stack.pop
      ret << LineRange.new(begin_cmd[0], last_num + 1)
    end
    ret
  end

  # @return [Array<[LineRange]>] ranges
  # @return [Array<[LineRange]>]
  def self.merge_ranges(ranges)
    # @type [LineRange] merged
    merged = []
    sorted = ranges.sort_by(&:begin)
    sorted.each do |test|
      if merged.empty? || merged.last.end < test.end
        merged << test
      else # 有重合
        temp = merged.pop
        merged << LineRange.new(temp.begin, [test.end, temp.end].max)
      end
    end
    merged
  end
end

class FileIgnoreChecker
  attr_accessor :path, :rule_name

  def initialize(path:, rule_name:)
    @path = path
    @rule_name = rule_name
  end

  # @return [Array<LineRange>]
  def ignore_ranges
    @ignore_ranges ||=
      begin
        ranges = IgnoreCmd.parse_ranges(path, rule_name)
        IgnoreCmd.merge_ranges(ranges)
      end
  end

  # @param [Integer] start_line
  # @param [Integer] end_line
  def ignore_range?(start_line, end_line)
    ignore_ranges.find do |range|
      range.begin <= start_line && start_line <= range.end && range.begin <= end_line && end_line <= range.end
    end
  end
end

def test_parse(rule_name)
  assert_nil = lambda do |line|
    cmd = IgnoreCmd::Types.parse_type(line, rule_name)
    raise "assert failed. expect nil. cmd: #{cmd}" unless cmd.nil?
  end
  assert = lambda do |exp, line|
    cmd = IgnoreCmd::Types.parse_type(line, rule_name)
    raise "assert failed. expect: #{exp}, cmd: #{cmd}, line: #{line}" unless cmd == exp
  end

  IgnoreCmd::Types.all.each do |cmd|
    assert_nil.call("lint:#{cmd} #{rule_name}")
    assert_nil.call("//lint:#{cmd} #{rule_name}")
    assert_nil.call("// lint:#{cmd}")
    assert_nil.call("// lint:#{cmd}A")

    assert.call(cmd, "// lint:#{cmd} #{rule_name}")
    assert.call(cmd, "// lint:#{cmd} #{rule_name} - 用户/业务无关数据，不进行统一存储管控检查")
    assert.call(cmd, "//  lint:#{cmd} #{rule_name}")
    assert.call(cmd, "//  lint:#{cmd} #{rule_name} - 用户/业务无关数据，不进行统一存储管控检查")
    assert.call(cmd, "//   lint:#{cmd}  #{rule_name}")
    assert.call(cmd, "//   lint:#{cmd}  #{rule_name} - 用户/业务无关数据，不进行统一存储管控检查")
  end
end

# test_parse('lark_storage_check')

# path = '/Users/zhangwei/BDCodes/iOS-client/bin/quality/lint/test.swift'
# ranges = IgnoreCmd.parse_ranges(path, 'lark_storage_check')
# merged = IgnoreCmd.merge_ranges(ranges)
# merged.each do |range|
#   puts "#{range.begin}, #{range.end}"
# end
