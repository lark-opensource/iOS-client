# frozen_string_literal: true

require 'singleton'
require 'set'

# usage:
# $0 [pod_dir*]

class DirectDepChecker
  include Singleton
  # @!method self.instance
  #  @return [DirectDepChecker]

  # @return [Array<String>]
  def deps_in_dir(dir)
    # FIXME: C header dependency
    # @testable import XX
    # @_exported import XX
    pipe_cmd = lambda do |cmd|
      cmd.push(dir)
      if exclude_path&.empty? == false and !Thread.current[:disable_exclude_path]
        cmd.concat(exclude_path.map { |v| "-g!#{v}" })
      end
      IO.popen(cmd) { |io| io.readlines(chomp: true).sort.uniq }.map { |n| module_to_pod[n] || n }
    end
    # swift
    deps = pipe_cmd.(['rg', '--vimgrep', '-tswift', '-oIN', '--no-column', '-r$1',
                      '^\s*(?:@\w+\s*)?import\s+(?:(?:class|enum|struct|protocol)\s*)?(\w+)'])
    # c family
    deps.concat pipe_cmd.(['rg', '--vimgrep', '-tcpp', '-tobjc', '-tobjcpp', '-oIN', '--no-column', '-r$1$2',
                           '^\s*#(?:import|include)\s*["<]([+\w]+)/|^\s*@import\s+([+\w]+);'])

    deps
  end

  # @return [Enumerable<String>]
  def deps_in_podspec(spec)
    # 现在没有把文件和subspec关联起来，所以使用和声明可能并不完全一致，只是保证整体的依赖一致
    # 另外可能有条件编译, 和文件也不是一一对应的，也不好区分所有的场景
    spec = to_spec(spec)
    (spec.dependencies + spec.recursive_subspecs.reject(&:non_library_specification?).flat_map(&:dependencies))
      .to_set(&:root_name).delete(spec.name)
  end

  def missing_deps_in_podspec(spec)
    spec = to_spec(spec)
    dir = File.dirname(spec.defined_in_file)
    Set.new(deps_in_dir(dir))
       .subtract(ignored_deps)
       .subtract(deps_in_podspec(spec))
       .delete(spec.name)
  end

  def extra_deps_in_podspec(spec)
    spec = to_spec(spec)
    dir = File.dirname(spec.defined_in_file)
    Set.new(deps_in_podspec(spec))
       .subtract(deps_in_dir(dir))
       .subtract(ignored_deps)
  end

  # @return [Hash] {miss: Set, add: Set}
  def diff_deps_in_podspec(spec)
    # FIXME: exclude_path会导致对应文件里使用的依赖变成多余依赖。
    # 要把subspec包含的文件关联起来才能精确了
    spec = to_spec(spec)
    dir = File.dirname(spec.defined_in_file)
    in_dir = deps_in_dir(dir)
    in_spec = deps_in_podspec(spec)
    return {
      miss: Set.new(in_dir).subtract(ignored_deps).subtract(in_spec).delete(spec.name),
      extra: Set.new(in_spec).subtract(in_dir).subtract(ignored_deps)
    }
  end

  def clear_extra_in_podspec(spec)
    # NOTE: 清理依赖要精确.. 目前看只能少清，不能多清
    Thread.current[:disable_exclude_path] = true
    spec = to_spec(spec)
    extra = extra_deps_in_podspec(spec)
    return if extra.empty?

    dep_pattern = /dependency\(?\s*['"](\w+)/
    lines = File.readlines(spec.defined_in_file).reject { |line|
      (m = dep_pattern.match(line) and extra.include? m[1])
    }
    File.write(spec.defined_in_file, lines.join)
    true
  ensure
    Thread.current[:disable_exclude_path] = nil
  end

  # @return [Pod::Specification]
  def to_spec(path_or_spec)
    require 'cocoapods-core'
    return path_or_spec if path_or_spec.is_a? Pod::Specification
    return Pod::Specification.from_file(path_or_spec)
  end

  def config
    @config ||= begin
      require 'yaml'
      YAML.safe_load_file(File.join(__dir__, 'direct_dep_check.config.yml'))
    end
  end

  def ignored_deps
    return @ignored_deps if defined?(@ignored_deps)
    @ignored_deps = Dir[File.join(`xcrun --show-sdk-path --sdk iphoneos`.chomp, '**/*.tbd')]
                    .map { |v| File.basename(v, '.tbd') }
    @ignored_deps.concat(config['ignored_deps'])
    return @ignored_deps
  end

  def module_to_pod
    config['module_to_pod']
  end

  def exclude_path
    config['exclude_path']
  end

  def self.exclude_spec?(path)
    ['Mock/', 'Example/'].any? { |v| path.include?(v) }
  end
end

unless $main
  $main = true
  def print_usage(code)
    $stdout.puts <<~USAGE
      #{$0} pod_dir*
    USAGE
    exit code
  end

  def main(argv)
    print_usage(0) if %w[-h --help].any? { |w| argv.include? w }
    print_usage(0) if argv.empty?

    require 'cocoapods-core'
    require 'colored2'
    # require 'optparse'

    if argv[0] == "-e"
      # 临时代码
      extra_in_dir(argv[1])
      return
    end

    specs = argv.each_with_object(Set.new) do |path, s|
      if path.end_with?('.podspec')
        s << path
      elsif File.directory?(path)
        s.merge(`git -C '#{path}' ls-files`.split("\n").grep(/\.podspec$/).map { |name| File.join(path, name) })
      end
    end
    report = proc do |spec, out|
      puts "#{File.basename spec, '.podspec'}:".blue
      out[:miss].each { |name| puts "miss: #{name}" }
      out[:extra].each { |name| puts "extra: #{name}" }
    end
    data = specs.map do |spec| # rubocop:disable all
      next if DirectDepChecker.exclude_spec?(spec)

      out = DirectDepChecker.instance.diff_deps_in_podspec(spec)
      next if out[:miss].empty? && out[:extra].empty?
      report.call(spec, out)
      [spec, out]
    end.compact.to_h
  end

  def extra_in_dir(dir)
    specs = `fd -e podspec . '#{dir}'`.lines(chomp: true)
    Thread.current[:disable_exclude_path] = true
    specs.each do |spec|
      next if DirectDepChecker.exclude_spec?(spec)

      extra = DirectDepChecker.instance.extra_deps_in_podspec(spec)
      next if extra.empty?

      puts ">>> extra in spec: #{spec}"
      puts extra.to_a
    end
  ensure
    Thread.current[:disable_exclude_path] = nil
  end

  def repl
    puts 'clearing'
    data = specs.map do |spec| # rubocop:disable all
      next if DirectDepChecker.exclude_spec?(spec)

      puts spec if DirectDepChecker.instance.clear_extra_in_podspec(spec)
    end

    # data.each_value.with_object(Set.new) do |v, memo|
    #   memo.merge(v[:extra])
    # end
  end

  main ARGV
end
