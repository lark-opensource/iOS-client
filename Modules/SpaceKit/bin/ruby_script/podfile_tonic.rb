#!/usr/bin/env ruby
# frozen_string_literal: true

# 这个文件里只存放ios-client only的脚本

require 'json'
require 'lark/project/podfile_mixin'

# 保留兼容。podfile里尽量使用lark_env的扩展方法获取相关的环境变量
# TODO: 统一用$lark_env
PackageEnv = $lark_env

# 清理错误的缓存，先保留一段时间
def clean_wrong_cache
  wrong_cdn_dir = Pathname('~/.cocoapods/repos/cocoapods-').expand_path
  wrong_cdn_dir.rmtree if wrong_cdn_dir.exist?
end

# 打印 Xcode 版本提醒到控制台。
def puts_xcode_version_tips
  message = <<-MESSAGE
  自2020年10月16日（Lark-Version: 3.36.0-alpha）起，打包任务将切换为使用Xcode12(Swift5.3)构建。
  在命令行运行 `rake xcode` 以获取更多更新日志。

  Starting October 16, 2020 (Lark-Version: 3.36.0-alpha), the packaging task will switch to build with Xcode12(Swift5.3).
  run `rake xcode` for more detail.
  MESSAGE

  Lark::UI.multiline_notice(message)
end

require 'xcodeproj'

module Tonnic
  module Patch
    def self.adjustExtension(project, target_name = 'Lark', extension_name = 'SmartWidget')
      target = project.targets.find { |target| target.name == target_name }
      phase = target.build_phases.find { |phase| phase.display_name.include? 'Embed App Extensions' } if target
      file = phase.files.find { |file| file.display_name.include? extension_name } if phase
      phase.files.delete file if file
    end

    # end for adjustExtension
  end # end for Patch
end # end for Apple

# 线下覆盖率需要修改主工程
def fix_offline_coverage(larkPro)
  if $lark_env.offline_coverage_enable
    larkPro.targets.each do |target|
      next unless target.name == 'Lark'

      target.build_configurations.each do |config|
        next unless config.name == 'Release'

        config.build_settings['CLANG_COVERAGE_MAPPING'] = 'YES'
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'YES'
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -fprofile-instr-generate -fcoverage-mapping'
        config.build_settings['OTHER_LDFLAGS'] << ' -fprofile-instr-generate'
        config.build_settings['OTHER_SWIFT_FLAGS'] << ' -profile-generate -profile-coverage-mapping'
      end
    end
  end
end
