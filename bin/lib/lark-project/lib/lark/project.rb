# frozen_string_literal: true

require_relative 'project/version'

module Lark
  # NOTE: 计划是以后会有一个专门的Lark模块，这个库应该只放project相关的.. 不过暂时先放在这，以后lark专门的库出来了，再重构复用
  class Error < StandardError; end
  class ExternalError < Error; end
  class UnsupportedError < Error; end

  autoload :Plist, File.expand_path('./tool/plist.rb', __dir__)
  autoload :Strings, File.expand_path('./tool/strings.rb', __dir__)
  autoload :UI, File.expand_path('./tool/ui.rb', __dir__)
  autoload :Misc, File.expand_path('./tool/misc.rb', __dir__)

  # 用于配置同步的一些基础代码和配置复用
  module Project
    autoload :Environment, File.expand_path('./project/environment.rb', __dir__)
    autoload :Lockfile, File.expand_path('./project/lockfile.rb', __dir__)
  end
end
