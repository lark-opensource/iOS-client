# frozen_string_literal: true

require 'xcodeproj'

# extension
module Xcodeproj
  # extension
  class Project
    # rubocop:disable Metrics

    # Add assembly file as build source to target
    #
    # @param file_name [String] swift file name
    # @return [Pathname] swift path
    def add_assembly(file_name)
      target = targets.first
      build_phase = target.source_build_phase

      find_file_ref = lambda { |f|
        ret = build_phase.files.find { |x| File.basename(x.file_ref.real_path.to_s) == f }
        ret&.file_ref
      }

      ref = find_file_ref.call(file_name)
      return ref.real_path unless ref.nil?

      main_ref = find_file_ref.call('main.swift')
      if main_ref
        new_path = main_ref.real_path.parent.join(file_name)
        # 参考 main.swift 构建 file_ref
        file_ref = new_file(new_path.to_s, main_ref.source_tree)
        file_ref.fileEncoding = main_ref.fileEncoding
        file_ref.include_in_index = main_ref.include_in_index
        file_ref.move main_ref.parent
        file_ref.set_path(new_path)
        target.source_build_phase.add_file_reference(file_ref)
        save
        new_path
      else
        project_dir.join(file_name)
      end
    end
    # rubocop:enable Metrics
  end
end