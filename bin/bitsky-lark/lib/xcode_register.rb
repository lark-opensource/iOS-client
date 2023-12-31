# 检查环境变量 XCODE_VERSION 是否存在
if ENV['XCODE_VERSION']
    xcode_version = ENV['XCODE_VERSION']
    puts "Environment variable XCODE_VERSION: #{xcode_version}"
  
    # 构建 Xcode 安装路径
    register_xcode_path = "/Applications/Xcode-#{xcode_version}.app"
  
    # 检查 Xcode 路径是否存在
    if File.directory?(register_xcode_path)
      # 执行 register 指令
      puts "Registering Xcode version #{xcode_version}"
      system("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f #{register_xcode_path}")
    else
      puts "Xcode version #{xcode_version} not found at #{register_xcode_path}"
    end
end