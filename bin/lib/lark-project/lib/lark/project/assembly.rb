# frozen_string_literal: true

module Lark
  module Project
    module Assembly
      require 'pathname'
      require_relative './assembly/search_item'
      require_relative './assembly/search_item_v2'  # v2 使用一段时间没问题后，删掉 `search_item`
      require_relative './assembly/gen_content'

      # 表示一个 Assembly Item，包括 class，pod 信息
      Item = Struct.new(:cls, :pod) do
        def to_hash
          { 'class' => @cls, 'pod' => @pod }
        end
      end

      # 搜索参数
      SearchParams = Struct.new(:base_path, :paths)

      # 新建文件
      #
      # @type target_dir [Pathname] 目标目录
      # @type class_name [String] swift 类名
      def self.new_file(target_dir, class_name = 'BaseAssembly')
        file_path = target_dir.join("#{class_name}.swift")
        File.write(file_path, gen_swift_content(class_name, []))
        file_path
      end

      # 重新生成 Assembly.swift 内容
      #
      # @param installer [Pod::Installer]
      # @param file_path [Pathname|Void] path/to/swift_file or nil
      def self.rebuild(installer, file_path: nil, use_v2: false)
        require 'cocoapods'
        require_relative './assembly/add_assembly'

        time = Time.now
        log 'will rebuild...'

        begin
          # 1. generate search params
          sandbox = Pod::Config.instance.sandbox
          # 提取 paths，并对 paths 进行分组，每次批量搜索的 paths 都有同一个 base_path，
          # 可基于 base_path 匹配出搜索解雇所在的 pod
          # @type params_list [Array<SearchParams>]
          params_list = []
          installer.pod_targets
                   .map { |pt| sandbox.pod_dir(pt.pod_name) }
                   .group_by { |path| path.parent.to_s }
                   .each_pair { |k, v| params_list.append(SearchParams.new(Pathname.new(k), v)) }

          # 2. search assemblies
          # @type [Array<Item>]
          items =
            if use_v2
              search_v2 params_list
            else
              search params_list
            end

          # 3. generate and write swift content
          file_path ||= begin
                          # 兼容旧的使用姿势，如果不传入 file_path，就去 project 中找名为 BaseAssembly.swift 的文件路径
                          # @type proj [Xcodeproj::Project]
                          proj = installer.aggregate_targets.first.user_project
                          proj.add_assembly 'BaseAssembly.swift'
                        end
          class_name = file_path.basename('.*')
          File.write(file_path, gen_swift_content(class_name, items))

          log_ok "rebuild succeed, spends #{Time.now - time} seconds. total count: #{items.count}"
        rescue => e
          # rebuild 失败不影响其他行为
          log_err "rebuild failed, err: #{e}."
        end
      end

      def self.log(msg)
        puts "[assembly] #{msg}"
      end

      def self.log_err(msg)
        log "\e[31m#{msg}\e[0m"
      end

      def self.log_ok(msg)
        log "\e[32m#{msg}\e[0m"
      end
    end
  end
end

# 兼容旧的使用姿势：`Assembly::rebuild installer`
Assembly = Lark::Project::Assembly
