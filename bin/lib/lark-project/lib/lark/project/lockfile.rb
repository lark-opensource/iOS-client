# frozen_string_literal: true

require 'fileutils'

module Lark
  module Project
    module Lockfile
      module_function

      def copy_if_pod_and_lockfile(source_root_path, lark_project_path)
        destination_path = "#{lark_project_path}/config"
        # copy strict file to container
        lock_file_path = "#{source_root_path}/Podfile.strict.lock"
        if File.file?(lock_file_path)
          puts "copying Podfile.strict.lock from #{lock_file_path} to #{destination_path}"
          Lark::Project::Lockfile.transform_lockfile_for_public(lock_file_path, destination_path)
        else
          puts 'warning: Podfile.strict.lock file not exist at ' + lock_file_path
        end
        # copy if_pod file to container
        if_pod_path = "#{source_root_path}/if_pod.rb"
        destination_path = "#{lark_project_path}/lib/lark/project/"
        target_path = File.join(destination_path, 'if_pod.rb')
        FileUtils.mkdir_p destination_path
        if File.file?(if_pod_path)
          puts "copying if_pod.rb from #{if_pod_path} to #{destination_path}"
          FileUtils.rm_f target_path
          FileUtils.cp(if_pod_path, target_path)
        else
          puts 'warning: if_pod.rb file not exist at ' + if_pod_path
        end
        # copy binary_expire.lock file to container
        binary_expire_lock_path = "#{source_root_path}/binary_expire.lock"
        if File.file?(binary_expire_lock_path)
          puts "copying binary_expire.lock from #{binary_expire_lock_path} to #{destination_path}"
          FileUtils.cp(binary_expire_lock_path, destination_path)
        else
          puts 'warning: binary_expire.lock file not exist at ' + binary_expire_lock_path
        end
      end

      def transform_lockfile_for_public(lockfile_path, destination_dic)
        FileUtils.mkdir_p(destination_dic)
        destination_path = "#{destination_dic}/#{File.basename(lockfile_path)}"
        input_lines = File.readlines(lockfile_path)
        # 去除依赖锁定文件中所有的本地依赖
        output_lines = input_lines.reject { |s| s.include?('(path') }
        File.open(destination_path, 'w') do |f|
          output_lines.each do |line|
            f.write line
          end
        end
      end

      def checkout_lockfile(path = nil)
        lock_file_path = "#{__dir__}/../../../config/Podfile.strict.lock"
        unless File.exist?(lock_file_path)
          warn 'no lockfile in this gem'
          return
        end
        path ||= Pod::Config.instance.strict_lockfile_path rescue nil # rubocop:disable all

        FileUtils.cp(lock_file_path, path) if path
      end
    end
  end
end
