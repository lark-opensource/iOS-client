# frozen_string_literal: true

require 'pathname'
require 'json'

module Lark
  module Project
    module Assembly
      # 搜索 assemblies
      #
      # @param params_list [Array<SearchParams>] search params list
      # @return [Array<Item>]
      def self.search_v2(params_list)
        do_search = if !`which rg`.empty?
                      log 'searching with ripgrep'
                      lambda { |params| rg_search_v2 params }
                    elsif !`which grep`.empty?
                      log 'searching with grep'
                      lambda { |params| grep_search_v2 params }
                    else
                      raise 'missing search util, such as `ripgrep`, `grep`'
                    end

        hash = Hash.new
        params_list.each do |params|
          do_search.call(params).each do |line|
            pod = Pathname(line).relative_path_from(params.base_path).to_s.split('/', 2)[0]
            hash[pod] ||= []
            hash[pod] << line
          end
        end

        tmp_dir = Pathname(Dir.mktmpdir)
        assembly_files_json_path = tmp_dir.join('assembly_files.json')
        assembly_files_json_path.write hash.to_json
        assembly_classes_json_path = tmp_dir.join('assembly_classes.json')

        # prepare `parser`
        parser_name = "parse_assembly"

        # @type target_dir [String] 下载文件解压后存储的位置
        load_file = lambda do |target_dir|
          url = "http://tosv.byted.org/obj/ee-infra-ios/tools/AutoAssembly/#{parser_name}_2022_10_24.zip"
          zip_path = "#{tmp_dir}/#{parser_name}.zip"
          cmd = <<-CMD
            curl -fsS #{url} --output '#{zip_path}'
            unzip -oq '#{zip_path}' -d '#{target_dir}'
            rm '#{zip_path}'

            chmod +x '#{target_dir}/#{parser_name}'
            codesign --force --deep --sign - ./#{parser_name} &> /dev/null || true
          CMD
          system(cmd, exception: true)
        end

        pods_dir = Pathname('./Pods')
        # @type [String] 可执行文件的路径
        parser_path_str =
          if pods_dir.exist?
            # 存储 parser 可执行文件的目录
            parser_cache_dir = pods_dir.join 'AutoAssembly'
            parser_cache_dir.mkdir unless parser_cache_dir.exist?
            parser_path = parser_cache_dir.join(parser_name)
            if parser_path.exist?
              log 'use local parser'
            else
              log 'load parser from tos...'
              load_file.call parser_cache_dir
            end
            parser_path.to_s
          else
            load_file.call tmp_dir
            tmp_dir.join(parser_name).to_s
          end

        cmd = "#{parser_path_str} '#{assembly_files_json_path}' '#{assembly_classes_json_path}'"
        system(cmd, exception: true)

        # @type [Array<Item>]
        items = []
        json_str = File.read(assembly_classes_json_path)
        classes = JSON.parse(json_str)
        classes.each_pair do |key, value|
          value.each do |cls|
            items << Item.new(cls, key)
          end
        end

        items.sort_by!(&:cls)
        items
      end

      private

      # 使用 ripgrep 进行搜索
      #
      # @param params [SearchParams] 搜索参数
      # @return [Hash<String: Array<String>>]
      def self.rg_search_v2(params)
        # rg search
        pattern = "'LarkAssemblyInterface'"
        path_str = params.paths.map { |p| "'#{p}'" }.join ' '
        cmd = "rg -ulL --color=never --type swift #{pattern} #{path_str}"
        # log cmd
        begin
          paths = `#{cmd}`.lines(chomp: true)
        rescue StandardError => e
          puts "search cmd: #{cmd}"
          raise e
        end
        paths
      end

      # 基于 grep 进行搜索
      #
      # @param params [SearchParams] 搜索参数
      # @return [Hash<String: Array<String>>]
      def self.grep_search_v2(params)
        # @type [Array<Pathname>] paths
        gen_cmd = lambda { |paths|
          path_str = paths.map { |p| "'#{p}'" }.join ' '
          "grep -FH -rlSs --color=never --include '*.swift' LarkAssemblyInterface #{path_str}"
        }
        # grep 搜索可能会报错 'Argument list too long'，进行拆分搜索，每次搜索 100 个路径
        index = 0
        step = 100
        paths = []
        while index < params.paths.length
          cmd = gen_cmd.call params.paths.slice(index, step)
          # log cmd
          lines = `#{cmd}`.lines(chomp: true)
          paths += lines
          index += step
        end
        paths
      end
    end
  end
end
