
def assert_dir(dir)
    assert_dir = `git rev-parse --show-toplevel`.strip + "/Modules/Infra/Libs/LarkAssertConfig/resources"
    Dir.chdir assert_dir do
      assert_dir_config_file = assert_dir + "/assert_dir_config"    
      File.delete(assert_dir_config_file) if File.exist?(assert_dir_config_file)
      `touch #{assert_dir_config_file}`
      if dir.instance_of? Symbol and dir.to_s == "disable"
        `echo #{dir.to_s} > #{assert_dir_config_file}`
        puts "关闭Assert转lldb功能"
      elsif dir.instance_of? String or dir.instance_of? Array or dir.instance_of? Symbol
        `echo #{dir.to_s} > #{assert_dir_config_file}`
        puts "关注的assert目录为: #{dir.to_s}"
      else
        raise "传入的assert_dir不合法，支持传入symbol, array，str类型"
      end  
    end
end
  