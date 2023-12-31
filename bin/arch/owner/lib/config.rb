require 'yaml'

module OwnerConfig
  MARK_TODO = 'MARK: 待填写'
  MARK_ADD_NEW = '# MARK: ADD NEW POD HERE'

  class OwnerConfigParseError < StandardError
    def initialize(message)
      super(message)
    end
  end

  class PodsConfig
    class Pod
      attr_accessor :team
      attr_accessor :owners
      attr_accessor :summary
      attr_accessor :doc

      def to_h
        {
          "team" => @team,
          "owners" => @owners,
          "summary" => @summary,
          "doc" => @doc
        }.compact
      end

      def owner_as_emails
        @owners.map { |name| name + '@bytedance.com' }
      end

      def self.from_h(hash)
        raise(OwnerConfigParseError, "Pod should be hash, but got: #{hash.inspect}") unless hash.is_a? Hash

        pod = Pod.new
        pod.team = hash['team'] or raise(OwnerConfigParseError, 'Pod should include team')
        pod.owners = hash['owners'] or raise(OwnerConfigParseError, 'Pod should include owners')
        raise(OwnerConfigParseError, "Owners should be string array, but got: #{pod.owners.inspect}") unless pod.owners.is_a? Array
        pod.summary = hash['summary']
        pod.doc = hash['doc']

        pod
      end

      def ==(other)
        other.is_a?(Pod) &&
          @team == other.team &&
          @owners == other.owners &&
          @summary == other.summary &&
          @doc == other.doc
      end
    end

    attr_accessor :config_path
    attr_accessor :team_options
    attr_accessor :pods

    # @param [String, nil] config_path
    # @param [Hash<String, untyped>] hash
    def initialize(config_path, hash)
      raise(OwnerConfigParseError, "Config should be hash, but got: #{hash.inspect}") unless hash.is_a? Hash

      attrs = hash['ATTRS']
      raise(OwnerConfigParseError, 'Config should include ATTRS') unless attrs.is_a? Hash

      @team_options = attrs['$TEAM']
      raise(OwnerConfigParseError, 'Config ATTRS should include $TEAM') unless @team_options.is_a? Array

      pods = hash['PODS']
      raise(OwnerConfigParseError, "Config should include PODS as hash, but got: #{pods.inspect}") unless pods.is_a? Hash

      @pods = pods.map do |k, v|
        begin
          [k, Pod.from_h(v)]
        rescue OwnerConfigParseError => e
          raise(OwnerConfigParseError, "The config of pod #{k} is invalid, " +
            "config: #{v.inspect}, reason: #{e}")
        end
      end.to_h
      @config_path = config_path
    end

    # @param [String] name  组件名
    # @param [Array<String>] owners 维护人列表
    # @param [String, nil] summary 可选项，组件摘要
    # @param [String, nil] doc 可选项，准入文档或介绍
    def add_pod!(name:, owners:, summary: nil, doc: nil)
      raise(OwnerConfigParseError, 'config_path should not be empty when adding a pod') if @config_path.nil? || @config_path.empty?

      pod = Pod.new
      pod.team = MARK_TODO
      pod.owners = owners
      pod.summary = summary
      pod.doc = doc

      # 查找 MARK 所在行
      config_lines = File.readlines(@config_path)
      mark_line_index = config_lines.index { |line| line.include? MARK_ADD_NEW }
      raise(OwnerConfigParseError, "Not found '#{MARK_ADD_NEW}'") if mark_line_index.nil?
      mark_line = config_lines[mark_line_index]
      # 获取该行当前的 indent
      indent_prefix = mark_line.match(/^\s*/)[0] || ""

      # 生成新 pod 的 YAML 配置
      new_pods_text =
        YAML.dump({ name => pod.to_h })
            .sub("---\n", "") # 去除第一行的 ---
            .rstrip # 去除最后的换行
            .prepend(indent_prefix) # 为第一行添加缩进
            .gsub("\n", "\n" + indent_prefix) # 为后续的每一行添加缩进

      # 插入到 MARK 行之前
      config_lines.insert(mark_line_index, new_pods_text)

      # TODO: 静默校验期间，暂不写入到文件，否则会产生 git 变更
      # File.open(@config_path, 'w') do |file|
      #   file.puts(config_lines)
      # end

      @pods[name] = pod
    end

    # @param [String] path
    # @return [PodsConfig]
    def self.load_file(path)
      begin
        hash = YAML.load_file(path)
        raise(OwnerConfigParseError, 'Could not load config from empty YAML file') unless hash
        PodsConfig.new(path, hash)
      rescue Psych::SyntaxError => e
        raise(OwnerConfigParseError, "YAML parse error: #{e}")
      end
    end
  end

  class ExtraConfig
    class Rule
      module MODE
        CATALOG = 'catalog'
        PATH = 'path'
        REGEX = 'regex'
      end

      attr_accessor :mode
      attr_accessor :prefix
      attr_accessor :rules
      attr_accessor :pattern
      attr_accessor :owners
      attr_accessor :required_approvals

      def initialize(hash)
        raise(OwnerConfigParseError, "Rule should be hash, but got: #{hash}") unless hash.is_a? Hash

        @mode = hash['mode'] or raise(OwnerConfigParseError, 'Rule should include mode')

        case @mode
        when MODE::CATALOG
          @prefix = hash['prefix'] or raise(OwnerConfigParseError, 'Catalog rule should include prefix')
          @rules = hash['rules']&.map { |h| Rule.new(h) } or raise(OwnerConfigParseError, 'Catalog rule should include sub-rules')
        when MODE::PATH, MODE::REGEX
          @pattern = hash['pattern'] or raise(OwnerConfigParseError, 'Non-catalog rule should include pattern')
          @owners = hash['owners'] or raise(OwnerConfigParseError, 'Non-catalog rule should include owners')
          @required_approvals = hash['required_approvals'] || 1
        else
          raise(OwnerConfigParseError, "Unknown rule mode: #{@mode}")
        end
      end

      def to_h
        hash = case @mode
               when MODE::CATALOG
                 {
                   'mode' => MODE::CATALOG,
                   'prefix' => @prefix,
                   'rules' => @rules&.map { |rule| rule.to_h }
                 }
               when MODE::PATH, MODE::REGEX
                 {
                   'mode' => @mode,
                   'pattern' => @pattern,
                   'owners' => @owners,
                   'required_approvals' => @required_approvals
                 }
               else
                 raise(OwnerConfigParseError, "Unknown rule mode: #{@mode}")
               end

        hash.compact
      end

      # @return [String]
      def path_as_regex
        raise(OwnerConfigParseError, "not path mode: #{self.to_h}")
        # TODO
      end

      # @return [Array<String>, nil]
      def owner_as_emails
        @owners&.map { |name| name + '@bytedance.com' }
      end
    end

    attr_accessor :rules

    # @param [Hash] hash
    def initialize(hash)
      raise(OwnerConfigParseError, "Config should be hash, but got: #{hash}") unless hash.is_a? Hash

      rules = hash['RULES']
      raise(OwnerConfigParseError, "Config should include rules as array, but got: #{rules.inspect}") unless rules.is_a? Array

      @rules = rules.map do |h|
        begin
          Rule.new(h)
        rescue OwnerConfigParseError => e
          raise(OwnerConfigParseError, "The rule config is invalid, " +
            "config: #{h.inspect}, reason: #{e}")
        end
      end
    end

    def flattened_pattern_to_rule
      Enumerator.new do |y|
        recursive_get_rules = lambda do |prefix, rules|
          rules.each do |rule|
            case rule.mode
            when Rule::MODE::CATALOG
              sub_prefix = prefix + rule.prefix
              recursive_get_rules.call(sub_prefix, rule.rules)
            when Rule::MODE::PATH, Rule::MODE::REGEX
              y << [prefix + rule.pattern, rule]
            else
              raise(OwnerConfigParseError, "Unknown rule mode: #{rule.mode}")
            end
          end
        end

        recursive_get_rules.call('', @rules)
      end.to_h
    end

    def self.load_file(path)
      begin
        hash = YAML.load_file(path)
        raise(OwnerConfigParseError, 'Could not load config from empty YAML file') unless hash
        ExtraConfig.new(hash)
      rescue Psych::SyntaxError => e
        raise(OwnerConfigParseError, "YAML parse error: #{e}")
      end
    end
  end
end
