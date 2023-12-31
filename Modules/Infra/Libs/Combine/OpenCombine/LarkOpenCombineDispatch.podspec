Pod::Spec.new do |spec|
  spec.name          = "LarkOpenCombineDispatch"
  spec.version       = "10.11.4"
  spec.summary       = "OpenCombine + Dispatch interoperability"

  spec.description   = <<-DESC
  Extends `DispatchQueue` with conformance to the `Scheduler` protocol
  DESC

  spec.homepage      = "https://github.com/broadwaylamb/OpenCombine/"
  spec.license       = "MIT"
  spec.module_name   = 'OpenCombineDispatch'

  spec.authors       = { "Sergej Jaskiewicz" => "jaskiewiczs@icloud.com" }
  spec.source        = { :git => "https://github.com/broadwaylamb/OpenCombine.git", :tag => "#{spec.version}" }

  spec.swift_version = "5.0"

  spec.osx.deployment_target     = "10.10"
  spec.ios.deployment_target     = "8.0"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target    = "9.0"

  spec.source_files = "Sources/OpenCombineDispatch/**/*.swift"
  spec.dependency     "LarkOpenCombine"
end
