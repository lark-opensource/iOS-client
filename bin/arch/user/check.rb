#!/usr/bin/env ruby
# frozen_string_literal: true

def print_usage(code)
  $stdout.puts <<~USAGE
    #{$0} \e[34m[check_dir:pwd]*\e[0m

    扫描对应目录里的一些基本关键迁移API
    可以在行尾添加
    `// user:(global|current|checked|migrated)`的注释
    来标注 全局|当前用户|人工确认|迁移中 等等特殊场景

    也可以行尾加
    `// (TODO:FIXME): user|用户隔离`
    的方式来人工标记一个没扫描到的待处理项

    \e[92;1mOptions:\e[0m
    \e[32m-f format:\e[0m 指定输出格式，可选值为: group(default), json, vim
    \e[32m-g globpattern:\e[0m 指定glob子目录的pattetrn，!开头可以排除目录。可以指定多次. 参考rg -g
    \e[32m-i globpattern:\e[0m 指定要运行的子任务, 使用!过滤。如果指定多次，以最后命中的pattern为准。子任务可选值为:
        container force_resolve global_resolve passport rustclient navigator boottask setting marker
    \e[32m--show-exception:\e[0m 显示例外标记的匹配
  USAGE
  # -fci 用于检查是否有增量扫描项
  exit code
end

def gem_deps
  require 'bundler/inline'
  gemfile do
    source 'https://rubygems.byted.org'
    gem 'colored2'
  end
  require 'colored2'
  require 'yaml'
  require 'set'
end

def check_and_install_deps
  system('which -s rg') or raise '请安装文本搜索工具riggrep: `brew install rg`'
end

def git_root
  $git_root ||= `git rev-parse --show-toplevel`.chomp
end

def pwd_relative
  $pwd_relative ||= Pathname(Dir.pwd).relative_path_from(git_root).to_s
end

def main(argv)
  print_usage(0) if argv.any? { |v| %w[-h --help].include? v } # rubocop:disable all
  check_and_install_deps
  gem_deps

  app = App.new
  # config
  config_path = File.join(__dir__, 'config.yml')
  config = YAML.load_file(config_path) if File.exist?(config_path)

  # parse
  app.parse!(argv, config)
  app.run!
end

class App
  # Input Params
  attr_accessor :filters, :rg_opts, :show_exception
  attr_accessor :config
  # @return [BaseFormatter]
  attr_accessor :format
  attr_accessor :dirs # root dir

  # cache property
  # @return [Array, false]
  # @sg-ignore
  def exclude_path
    if @exclude_path.nil?
      @exclude_path = relative_paths_git2pwd(config['excludePath']) if config
      @exclude_path = false if @exclude_path.nil? # avoid recompute
    end
    @exclude_path
  end
  attr_writer :exclude_path

  def global_types
    @global_types ||= Set.new config['globalType']
  end
  attr_writer :global_types

  def parse!(argv, config) # rubocop:disable all
    # after parse, should reset to a clean state
    self.config = config
    self.exclude_path = nil
    self.global_types = nil
    self.rg_opts = []
    self.filters = []

    it = argv.to_enum
    args = []
    begin
      # get from rest flags or next args
      get_short_param = lambda do |flag, i|
        flag.size > i ? flag[i..] : it.next
      end
      while v = it.next
        if v[0] == '-' && v[1] != '-' # short flag
          (1..).each do |i| # rubocop:disable all
            case v[i]
            when 'g' then break rg_opts.push('-g', get_short_param.(v, i + 1))
            when 'i' then break filters.push(get_short_param.(v, i + 1))
            when 'f'
              case f = get_short_param.(v, i + 1)
              when 'json', 'group', 'vim', 'ci' then self.format = f
              else
                raise "invalid format param #{f}"
              end
              break
            else raise "invalid short option #{v[i]}"
            end
          end
        else
          case v
          when '--show-exception'            then self.show_exception = true
          when '--'                          then loop { rg_opts.push it.next }
          else
            args.push v
          end
        end
      end
    rescue StopIteration
      # next
    end
    self.format = case self.format
                  when 'json' then JSONFormatter.new
                  when 'ci' then CIFormatter.new
                  when 'vim' then VIMFormatter.new
                  else GroupFormatter.new
                  end
    self.dirs = args
  end

  def run!
    if @format.is_a?(CIFormatter) and @format.checked_files.empty? || grep_files.empty?
      warn 'no files to check'
      return
    end

    tasks = %w[
      container
      force_resolve
      global_resolve
      passport
      variable_user
      rustclient
      navigator
      boottask
      setting
      marker
    ]
    tasks.each do |task|
      run = nil
      @filters.each do |f|
        if f[0] == '!'
          File.fnmatch?(f[1..], task, File::FNM_EXTGLOB) and run = false
        else
          File.fnmatch?(f, task, File::FNM_EXTGLOB) and run = true
        end
      end
      run.nil? and run = @filters.empty? || @filters.all? { |f| f[0] == '!' }
      send("check_#{task}") if run
    end
    format.finish
  end

  def check_container
    format.title 'container', 'check container register api'
    if grep('\.inObjectScope\(\.(?:user|container)\)')
      format.diag '[WARNING]请迁移到新的用户容器API，单例需要确保用户安全。参考<https://bytedance.feishu.cn/wiki/wikcn9Toj60UIFOR0W0JnDMsBvP#QG6QdIqoCoMkk4xsjeEcoNbUnhd>'
    end
  end

  def check_force_resolve
    format.title 'force_resolve', 'check force resolve api'
    # 尽量匹配所有旧的resolve使用，而不仅仅是同一行有强解包的使用
    pattern = '(?:\br|(?<!pageC)ontainer|esolver|shared|[ )])[?!]?\.resolve\((?!\w+:)\s*([.\w]*)'
    # pattern = 'resolve\(.*\)!'
    exclude_path = [
      'Modules/ByteView/Modules/ByteView/',
      'Modules/ByteView/Modules/ByteViewTab'
    ]
    type_pattern = /(\w+).self/
    has_match = grep(pattern, exclude_path: relative_paths_git2pwd(exclude_path)) do |result|
      type = (type_pattern =~ result.match[1]) && $1
      next nil if type and global_types.include?(type)
      result
    end
    format.diag '[WARNING]请使用resolve(assert:), 并处理相关异常，避免强解包' if has_match
  end

  def check_global_resolve
    format.title 'global_resolve', 'check global_resolve usage'
    inject_pattern = /(?:@\w+).*var\s+\S+\s*:\s*(\w+)/
    resolve_pattern = /\.resolve\((?:\w+:)?\s*(\w+).self/
    has_match = grep('@Inject|@Provider\b|implicitResolver' \
                     '|Container.shared(?!\.(?:get(?:Current)?UserResolver|inObjectScope))') do |result|
      type = if result.match[0][0] == '@'
               inject_pattern =~ result.text and $1
             else
               resolve_pattern =~ result.text and $1
             end
      next nil if type and global_types.include?(type)
      result
    end
    format.diag '[WARNING]只有用户无关服务可以使用, 请检查以上调用是否符合预期' if has_match
  end

  def check_variable_user
    format.title 'variable_user', 'check variable user api'
    if grep('\.(?:getCurrentUserResolver|foregroundUser)|var\s+\w+:\s*UserResolver\?(?!\s*\{)')
      format.diag '[WARNING]避免依赖可变当前用户'
    end
  end

  def check_passport
    format.title 'passport', 'check passport api'
    if grep('\bAccountService(?!UG)|\bLauncherDelegate\b')
      format.diag '[WARNING]请迁移到passport新服务接口, 并且优先考虑传递用户容器，避免依赖当前用户. 参考<https://bytedance.feishu.cn/docx/doxcn8fvSqA3Iu2kfbE3jZmSWhb>'
    end
  end

  def check_rustclient
    format.title 'rustclient', 'check rustclient api'
    # container, resolver, userResolver, syncResolver.. etc end with r
    if grep('(?:container|r|resolve)\??\.pushCenter|class .*:\s*\w+RustPushHandler\b')
      format.diag '[WARNING]请迁移到新的用户隔离的API, 参考<https://bytedance.feishu.cn/wiki/wikcnUx2GpdTg70EqRp36N1hTOd>'
    end
  end

  def check_navigator
    format.title 'navigator', 'check navigator api'
    if grep('Navigator\.shared\.(?!register)|\b(?:Typed)?RouterHandler')
      format.diag '[WARNING]请确认用户相关的路由迁移到新的隔离API, 参考<https://bytedance.feishu.cn/wiki/wikcnWu94WA6tFf2aIbuqDksxLd>'
    end
  end

  def check_boottask
    format.title 'boottask', 'check BootTask'
    if grep('class.*\b(?:Flow|Async|Branch|FirstTabPreload)?BootTask\b')
      format.diag '[WARNING]请确认用户相关的启动任务，应该使用对应的UserBootTask, 参考<https://bytedance.feishu.cn/wiki/wikcnybxetkGDfUToXTr5JsW6Eb#doxcn2kWEoCkUmE8e0UKFrkibBd>'
    end
  end

  def check_setting
    format.title 'setting', 'check LarkSetting'
    pattern = '(?:\b(?:FeatureGatingManager|LarkFeatureGating|SettingManager)\.shared' \
              '|\bFeatureGatingManager\.realTimeManager' \
              '|@FeatureGatingValue|@RealTimeFeatureGating|@RealTimeFeatureGatingProvider|@FeatureGating' \
              '|\bFeatureSwitch\.share\.bool' \
              ')'
    if grep(pattern)
      format.diag '[WARNING]确认FG和Settings相关调用是否用户相关，相关需要使用对应API避免串数据。参考<https://bytedance.feishu.cn/docx/doxcnJ7dzCiiqRxTi7yc9Jhebxe#doxcnc44oYeIYGqmwMpdRLduDyc>'
    end
  end

  def check_marker
    format.title 'marker', 'check manual marker'
    pattern = '//\s*(?i)(?:(?:TODO|FIXME).*用户隔离|(?:TODO|FIXME)\W+user)'
    format.diag '[WARNING] 请检查以上遗留项是否已经处理' if grep(pattern)
  end

  def grep_cmd(regex, exclude_path: nil)
    unless @show_exception
      regex = "(?:#{regex})(?!.*//\\s*(?i)" \
              '(?:Global|foregroundUser|user:(?:global|current|checked)' \
              '|(?:TODO|FIXME).*用户隔离|(?:TODO|FIXME)\W+user\b))'
    end
    cmd = ['rg', '--pcre2', '-tswift', regex] # 排除过滤标记
    cmd.concat(dirs) if dirs
    cmd.concat(exclude_path.map { |v| "-g!#{v}" }) if exclude_path&.empty? == false
    cmd.concat(self.exclude_path.map { |v| "-g!#{v}" }) if self.exclude_path&.empty? == false
    cmd.concat(@rg_opts) unless @rg_opts.empty?
    cmd
  end

  # @yieldparam [GrepResult] return nil or GrepResult to accept it
  def grep(regex, exclude_path: nil)
    env = {}
    env['RIPGREP_CONFIG_PATH'] = @format.rg_ci_config_file.path if @format.is_a?(CIFormatter)

    cmd = grep_cmd(regex, exclude_path: exclude_path)
    cmd.insert(1, '--vimgrep')
    results = []
    regex = Regexp.new(regex)
    comment = %r{^\s*//}
    IO.popen(env, cmd) do |io|
      io.each_line(chomp: true) do |line|
        # result is nil or same as line.split
        # @sg-ignore
        result = GrepResult.new(*line.split(':', 4), regex)
        next if comment.match? result.text
        next if block_given? and !(yield result)
        results << result
      end
    end

    @format.handle_grep_results results
    return !results.empty?
  end

  GrepResult = Struct.new(:path, :line, :column, :text, :regex)
  class GrepResult
    # @!parse
    #  attr_reader :path, :line, :column, :text, :regex

    # @return [MatchData]
    def match
      return @match if defined?(@match)
      @match = regex.match(text)
      return @match
    end
  end

  # the files to be grepped
  def grep_files
    env = {}
    env['RIPGREP_CONFIG_PATH'] = @format.rg_ci_config_file.path if @format.is_a?(CIFormatter)

    cmd = ['rg', '-tswift', '--files'] # 排除过滤标记
    cmd.concat(dirs) if dirs
    # cmd.concat(args) unless args.empty?
    cmd.concat(exclude_path.map { |v| "-g!#{v}" }) if exclude_path&.empty? == false
    cmd.concat(@rg_opts) unless @rg_opts.empty?

    IO.popen(env, cmd) { |io| io.readlines(chomp: true) } # files
    # .tap { |files| warn("files:\n#{files.join("\n")}") }
  end

  # convert paths from relative git to relative pwd
  def relative_paths_git2pwd(paths)
    return paths unless paths
    return paths if pwd_relative == '.'

    paths.map { |v| relative_path_git2pwd v }.compact
  end

  # return relative path in pwd, or nil if not match
  def relative_path_git2pwd(path)
    return path.delete_prefix(pwd_relative) if path.start_with? pwd_relative
    return path if path.start_with? '**' # dir without prefix
    # ignore path without same prefix
  end

  class BaseFormatter
    # abstract method:
    # @!method title(type, msg)
    #   start of a grep type
    # @!method diag(msg)
    #   end of a grep type if has match
    # @!method handle_grep_results(results)
    #   handle grep results
    #   @param results [Array<GrepResult>]

    def finish; end
  end
  class GroupFormatter < BaseFormatter
    def title(_type, msg)
      puts(('# ' + msg).cyan)
    end
    def diag(msg)
      puts msg.yellow
    end
    def handle_grep_results(results)
      results.group_by(&:path).each do |path, matches|
        puts path.blue
        # @param [GrepResult]
        matches.each do |match|
          print match.line.to_s.green, ':'
          if v = match.match
            print v.pre_match, v[0].red.bold, v.post_match, "\n"
          else
            puts match.text
          end
        end
      end
    end
  end
  class VIMFormatter < BaseFormatter
    def title(_type, msg)
      print('# ', msg, "\n")
    end
    def diag(msg)
      puts msg
    end
    def handle_grep_results(results)
      results.each do |result|
        puts [result.path, result.line, result.column, result.text].join(':')
      end
    end
  end

  class JSONFormatter < BaseFormatter
    MigratedRegex = %r{//\s*(?i)user:migrated}.freeze
    Record = Struct.new(:path, :start_line, :text, :issue, :desc, :migrated)
    class Record
      def to_json(*args)
        to_h.to_json(*args)
      end
    end

    def initialize
      @records = []
      super
    end
    def title(type, _msg)
      @current_type = type
      @current_records = []
    end
    def diag(msg)
      @current_records.each do |r|
        r.desc = msg
      end
      @records.concat(@current_records)
      @current_records = nil
    end
    def finish
      require 'json'

      # puts JSON.pretty_generate(
      puts JSON.fast_generate(
        {
          input: {
            commit: `git rev-parse HEAD`.chomp,
            branch: `git rev-parse --abbrev-ref HEAD`.chomp,
            steps: [100, 100, 300, 500, 1000],
            local_repo_path: git_root,
            bitable_detail_app_token: 'XCUWbdXVIarbLZsQH6PczViynyh',
            bitable_detail_table_id: 'tblUpbjqUuiyv2hU',
            bitable_score_app_token: 'XCUWbdXVIarbLZsQH6PczViynyh',
            bitable_score_table_id: 'tblbD5cPgxtF8ZxB'
          },
          records: @records
        }
      )
    end

    def handle_grep_results(results)
      results.each do |result|
        add_record(result.path, result.line, result.text)
      end
    end

    def add_record(path, line, text)
      r = Record.new
      r.issue = @current_type
      r.path, r.start_line, r.text = path, line, text
      r.start_line = r.start_line.to_i
      r.text.strip!
      r.migrated = MigratedRegex.match?(r.text)
      @current_records << r
    end
  end
  class CIFormatter < JSONFormatter
    def target_commit
      'origin/' + ENV.fetch('WORKFLOW_REPO_TARGET_BRANCH', 'develop')
    end

    def checked_files
      @checked_files ||= begin
        config = ci_config
        normalize_glob = lambda do |glob|
          if glob.end_with?('/')
            (glob + '**')
          elsif Dir.exist?(glob)
            (glob + '/**')
          else
            glob
          end
        end
        include_path = config['includePath'].map(&normalize_glob)
        exclude_path = config['excludePath'].map(&normalize_glob)

        `git diff --name-only --diff-filter=ACMRTX #{target_commit}...@ -- '*.swift'`
          .each_line(chomp: true).select do |line|
            include_path.any? { |glob| File.fnmatch?(glob, line) } and
              exclude_path.none? { |glob| File.fnmatch?(glob, line) }
          end
      end
    end

    def finish
      return if @records.empty?

      filter_changed_lines
      return if @records.empty?

      report_issue

      exit(2)
    end

    def filter_changed_lines
      changed_b = git_info.changed_b
      @records.select! do |r|
        changed_b[r.path]&.any? do |range|
          range.include?(r.start_line)
        end
        # .tap do |v|
        # warn("[#{v.to_s[0]}]#{r.path}:#{r.start_line}".blue + ": #{r.text}")
        # end
      end
    end

    def report_issue
      @records.group_by(&:issue).each do |issue, records|
        puts(('# ' + issue + '  ' + records[0].desc).cyan)
        records.each do |r|
          puts("#{r.path}:#{r.start_line}".blue + ": #{r.text}")
        end
        puts('')
      end
    end

    # @return [Tempfile]
    # @sg-ignore
    # 用于限制只搜索改变的文件
    def rg_ci_config_file
      @rg_ci_config_file ||= begin
        require 'tempfile'
        # 写入CI配置参数到临时文件
        tmp_file = Tempfile.new('rg-config')
        checked_files.each do |file|
          # FIXME: 使用-g过滤的性能较差, 但如果直接放在args上，优先级又太高了.., 应该保证过滤优先
          tmp_file.write('-g', file, "\n")
        end
        tmp_file.close
        tmp_file # unlink when finalize
      end
    end

    def git_info
      # 因为搜索的当前代码，所以只能和@比较
      GitDiffInfo.new(*%W[#{target_commit}...@ -- *.swift])
    end

    def ci_config
      config_path = File.join(__dir__, 'ci.yml')
      YAML.load_file(config_path) if File.exist?(config_path)
    end
  end
end
class GitDiffInfo
  attr_reader :args

  def initialize(*args)
    @args = args
  end

  def diff
    @diff ||= IO.popen(['git', 'diff', '-U0', *args], &:read)
  end

  def changed_a
    @changed_a || begin
      analyze
      @changed_a
    end
  end

  def changed_b
    @changed_b || begin
      analyze
      @changed_b
    end
  end

  def analyze
    diff_a, diff_b = nil
    @changed_b = {}
    @changed_a = {}
    diff.each_line(chomp: true) do |line|
      case line
      when %r{^-{3} (?:a/)?(.*)$} then diff_a = $1
      when %r{^\+{3} (?:b/)?(.*)$} then diff_b = $1
      when /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/
        # start, length. start is 1-base
        a_s, a_c, b_s, b_c = $1.to_i, ($2 || 1).to_i, $3.to_i, ($4 || 1).to_i
        (@changed_a[diff_a] ||= []) << Range.new(a_s, a_s + a_c, true) if a_c > 0
        (@changed_b[diff_b] ||= []) << Range.new(b_s, b_s + b_c, true) if b_c > 0
      end
    end
  end
end

if $test
  $main = self
else
  main ARGV
end
