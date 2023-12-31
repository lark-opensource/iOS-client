Pod::Spec.new do |spec|
  spec.name          = "LarkCombine"
  spec.version = '5.30.0.5428090'
  spec.summary       = "Wrapper of OpenCombine and Combine"

  spec.description   = <<-DESC
  Wrapper of Apple's Combine and OpenCombine, OpenCombine is an open source implementation of Apple's Combine framework for processing values over time for device running lower than iOS 13.0.
  DESC

  spec.homepage      = "https://review.byted.org/a/lark/LarkCombine"
  spec.license       = "MIT"

  spec.authors       = { "Wang Yuanxun" => "wangyuanxun@bytedance.com" }
  spec.source        = { :git => "ssh://git.byted.org:29418/lark/LarkCombine", :tag => "#{spec.version}" }

  spec.swift_version = "5.3"
  spec.ios.deployment_target = "11.0"

  spec.source_files  = "LarkCombine/**/*.swift"

  spec.dependency "LarkOpenCombine"
  spec.dependency "LarkOpenCombineDispatch"
  spec.dependency "LarkOpenCombineFoundation"
end
