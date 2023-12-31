module Lark
  module Demo
    autoload :Builder, File.expand_path('./demo/builder/builder', __dir__)
    autoload :Automatic, File.expand_path('./demo/automatic/automatic', __dir__)
  end
end