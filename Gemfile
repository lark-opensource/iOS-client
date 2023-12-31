# frozen_string_literal: true
# Ensure this file is checked in to source control!

# NOTE: to ensure updated gems only use version from byted, not the newest local or official gems, use a clean dir for resolve dependency
# eg: BUNDLE_PATH=.bundle bundle lock
source 'https://rubygems.byted.org'

cocoapods_version = '1.13.0'

###### 我们自己的gem
if lark_pipeline_worksapce = ENV['LARK_PIPELINE_WORKSPACE']
  require File.realpath(File.expand_path(File.join(lark_pipeline_worksapce, 'scripts/local_gems.rb')))
  LarkPipeline::Rakefile::ComponentManager.instance.components.each do |com|
    gem com.name, path: com.workspace
  end
  begin
    gem 'pry-byebug'
    require 'pry-byebug'
  rescue LoadError
    # optional require
  end
else
  gem 'EEScaffold', '>= 0.1.0.pre'
  gem 'optimus_ios'
  gem 'brickwork'
end
gem 'lark-project', path: './bin/lib/lark-project'
# 使用共享缓存, 暂时用这个环境变量控制开关做测试
# if !ENV['WORKFLOW_JOB_ID'].nil?
  ENV['COCOAPODS_SHARED_CACHE'] ||= 'true'
  ENV['COCOAPODS_SHARED_CACHE_UPLOAD'] ||= 'true'
# else
#   ENV['COCOAPODS_SHARED_CACHE'] ||= 'true'
#   ENV['COCOAPODS_SHARED_CACHE_UPLOAD'] ||= 'true'
# end

###### 公司提供的Gem
gem 'cocoapods-byted-dependency-support', '1.0.0.pre.lark.0' # seer publish
gem 'activesupport', '< 7.0' # ruby 2.6兼容
gem 'cocoapods-xcremotecache', '100.0.11' 
gem 'cocoapods-monitor'
gem 'seer-hummer-hooks', '~> 0.0.43'
gem 'seer-hummer-apm', '~> 0.0.17' # pod和编译数据收集 https://bytedance.feishu.cn/wiki/wikcnFXcOTwnGkUJQNYyv7NQkkg
# pod install 提速,remove cocoapods-amicable https://bytedance.feishu.cn/docs/doccnFTUeA1JqmFAf5MhTcPwWob#90AEaL
# Cocoapods 1.12.0 需要升级到 1.0.2.alpha.24 以上
gem 'seer-optimize', '1.0.2.alpha.lark.29', '< 1.1'

# 使用RR_ENABLE=true 开启云端判决
# 使用RR_CDN_SOURCE=true 开启CDN
# if !ENV['WORKFLOW_JOB_ID'].nil? and ENV['RR_ENABLE'].nil? and ENV['RR_CDN_SOURCE'].nil?
#   # 在CI环境上灰度云端构建功能
#   case rand(3)
#   when 0 then ENV['RR_ENABLE'] = 'true'
#   when 1 then ENV['RR_CDN_SOURCE'] = 'true'
#   end
# end

# RR_ENABLE远端判决不能处理本地被移除的依赖。这样延迟lock更新或者删除的场景会有影响.
# 目前远端判决都先去掉了，先只用CDN..
ENV.delete('RR_ENABLE')
gem "cocoapods-remote-resolve", ENV['BITS_BITNEST_VERSION'] || '>= 0.1.2'

# 时机太晚了，需要在 pod install 命令执行前执行，也就是 plugin 逻辑
# ENV['COCOAPODS_INTEGRATE_SPECIFIC_TARGETS'] ||= 'true'
# ENV['COCOAPODS_TARGETS'] ||= 'Lark'
# ENV['COCOAPODS_CONFIGURATIONS'] ||= "Debug"

###### 第三方使用的Gem
gem 'cocoapods', cocoapods_version # 保证Bundle执行的和本地Podfile兼容
# gem 'cocoapods-amicable', '~> 0.3.0' # pod 1.7.0需要0.3.0以上, 用于去掉Podfile Checksum
gem 'rake'
gem 'xcov'
gem 'toml'
gem 'CFPropertyList'

###### 间接依赖降级
gem 'chef-utils', '16.6.14'
gem 'ffi', '1.15.5'
gem 'json', '2.3.1'
gem 'xcpretty', '0.3.1.1' # xcpretty 0.3.1.2 和 ruby 2.6.5 不兼容，导致 $HOME/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/xcpretty-0.3.1.2/lib/xcpretty/printer.rb:35:in `pretty_print': undefined method `empty?' for nil:NilClass (NoMethodError) # rubocop:disable all

###### fastlane的依赖
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

###### Config
# 隔离cocoapod缓存环境. cocoapod发现版本不一样会清缓存，这样多个版本混用时会互相清楚，造成并发问题。
ENV['CP_CACHE_DIR'] = File.join(Dir.home, 'Library/Caches/CocoaPods', cocoapods_version)
gem 'cocoapods-bitsky', '1.3.68'
gem 'progressbar'
gem 'bitsky-lark', :path => './bin/bitsky-lark'