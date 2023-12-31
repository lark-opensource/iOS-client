# frozen_string_literal: true

module Lark
  module Project
    module Assembly
      require 'pathname'

      # 搜索 assemblies
      #
      # @param params_list [Array<SearchParams>] search params list
      # @return [Array<Item>]
      def self.search(params_list)
        do_search = if !`which rg`.empty?
                      log 'searching with ripgrep'
                      lambda { |params| rg_search params }
                    elsif !`which grep`.empty?
                      log 'searching with grep'
                      lambda { |params| grep_search params }
                    else
                      raise 'missing search util, such as `ripgrep`, `grep`'
                    end

        params_list
          .map { |params| do_search.call params }
          .flat_map { |t| t }
          .sort_by(&:cls)
      end

      private

      # inner raw item
      class RawItem
        attr_accessor :path, :lines

        def initialize(path, lines)
          raise 'path should be a valid String' unless path.is_a?(String) && !path.empty?
          raise 'lines should be an Array' unless lines.is_a?(Array)

          @path = path
          @lines = lines
        end

        # 生成 Item
        #
        # @param base_path [Pathname] 用于基于 path 提取 Pod 的名字
        # @return [Item, void]
        def into_item(base_path)
          return if lines.empty?

          # rubocop:disable Layout/LineLength

          # cls_def components:
          # - space = '\s'
          # - final = "(?:(?:final)#{space}+)"
          # - access = "(?:(?:open|public)#{space}+)"
          # - name = '(?<cls>\w+)'
          #
          # cls_def = /^(?:#{space}*#{final}?#{access}#{final}?)class#{space}+#{name}#{space}*:/
          cls_def = /^(?:\s*(?:(?:final)\s+)?(?:(?:open|public)\s+)(?:(?:final)\s+)?)class\s+(?<cls>\w+)\s*:/
          cls_init = /^\s*(?:public|open)\s+init\s*\((?<args>[\s\S]*)\)/

          # rubocop:enable Layout/LineLength

          # @type [String]
          pod = Pathname(path).relative_path_from(base_path).to_s.split('/', 2)[0]

          # parse class name
          first = cls_def.match(lines[0].strip)
          return unless first && first['cls']

          # @type [String]
          cls = first['cls']

          # find init(). eg: init() init(config = xxx)
          init_line = lines[1..-1].find { |line| cls_init =~ line.strip }
          return unless init_line

          init_ret = cls_init.match init_line
          return unless init_ret['args']

          # init 参数列表，去掉含有默认值的
          args_list = init_ret['args'].strip.split(',').filter { |s| !s.include? '=' }
          return unless args_list.empty?

          Item.new cls, pod
        end
      end

      # 使用 ripgrep 进行搜索
      #
      # @param params [SearchParams] 搜索参数
      # @return [Array<Item>]
      def self.rg_search(params)
        # rg search
        pattern = 'LarkAssemblyInterface'
        path_str = params.paths.map { |p| "'#{p}'" }.join ' '
        cmd = "rg -uL --type swift --no-heading --no-column --no-line-number -A 10 #{pattern} #{path_str}"
        # puts cmd
        begin
          lines = `#{cmd}`.lines(chomp: true)
        rescue StandardError => e
          puts "search cmd: #{cmd}"
          raise e
        end

        # parse lines
        raw_items = parse_lines lines
        raw_items.map { |i| i.into_item(params.base_path) }.compact
      end

      # 基于 grep 进行搜索
      #
      # @param params [SearchParams] 搜索参数
      # @return [Array<Item>]
      def self.grep_search(params)
        # @type [Array<Pathname>] paths
        gen_cmd = lambda { |paths|
          path_str = paths.map { |p| "'#{p}'" }.join ' '
          "grep -FH -A 10 -rSs --include '*.swift' LarkAssemblyInterface #{path_str}"
        }
        # grep 搜索可能会报错 'Argument list too long'，进行拆分搜索，每次搜索 100 个路径
        index = 0
        step = 100
        raw_items = []
        while index < params.paths.length
          cmd = gen_cmd.call params.paths.slice(index, step)
          # log cmd
          lines = `#{cmd}`.lines(chomp: true)
          raw_items += parse_lines lines
          index += step
        end

        raw_items.map { |i| i.into_item(params.base_path) }.compact
      end

      # 处理 lines，生成 Array<RawItem>
      #
      # @param lines [Array<String>]
      # @return [Array<RawItem>]
      def self.parse_lines(lines)
        file_sep = '--' # 文件分隔符
        lines.append file_sep
        last_item = nil
        raw_items = []
        lines.each do |line|
          if line.start_with?(file_sep)
            raw_items.append last_item if last_item
            last_item = nil
            next
          end
          if last_item.nil?
            arr = line.split(':', 2)
            raise 'unexpected parse result' if arr.length != 2

            last_item = RawItem.new arr[0], [arr[1]]
          else
            prefix = last_item.path
            raise "unexpected parse result, line: #{line}, prefix: #{prefix}" unless line.start_with?(prefix)

            temp = line.gsub(prefix, '')
            mark, fixed_line = temp[0], temp[1..-1]

            if mark == ':' # match line marker
              raw_items.append last_item
              last_item = RawItem.new prefix, [fixed_line]
            else
              last_item.lines.append fixed_line
            end
          end
        end
        raw_items
      end

    end
  end
end
