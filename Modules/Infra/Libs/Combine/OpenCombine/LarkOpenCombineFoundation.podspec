Pod::Spec.new do |spec|
    spec.name          = "LarkOpenCombineFoundation"
    spec.version       = "10.11.4"
    spec.summary       = "OpenCombine + OpenCombineFoundation interoperability"
  
    spec.description   = <<-DESC
    Adds publishers to Foundation types like NotificationCenter, URLSession etc.
    DESC
  
    spec.homepage      = "https://github.com/broadwaylamb/OpenCombine/"
    spec.license       = "MIT"
    spec.module_name   = 'OpenCombineFoundation'
  
    spec.authors       = { "Sergej Jaskiewicz" => "jaskiewiczs@icloud.com" }
    spec.source        = { :git => "https://github.com/broadwaylamb/OpenCombine.git", :tag => "#{spec.version}" }
  
    spec.swift_version = "5.0"
  
    spec.osx.deployment_target     = "10.10"
    spec.ios.deployment_target     = "8.0"
    spec.watchos.deployment_target = "2.0"
    spec.tvos.deployment_target    = "9.0"
  
    spec.source_files = "Sources/OpenCombineFoundation/**/*.swift"
    spec.dependency     "LarkOpenCombine"
  end
