require 'xcodeproj'
require 'pathname'
require 'find'
require 'lark/project/environment'

def get_executable_path(project_file, target_name, default_ext)
  xc_project = Xcodeproj::Project.open(project_file)
  xc_target = xc_project.targets.find do |target|
    target.name == target_name
  end
  debug_settings = xc_target.build_settings('Debug')

  # Assume that PRODUCT_NAME, PRODUCT_MODULE_NAME and WRAPPER_EXTENSION of
  # 'Debug' configuration are the same as other configurations
  product_name = debug_settings['PRODUCT_NAME']

  product_name = target_name if product_name.to_s.empty?

  product_module_name = debug_settings['PRODUCT_MODULE_NAME']
  product_module_name = product_name if product_module_name.to_s.empty?

  wrapper_extension = debug_settings['WRAPPER_EXTENSION']
  wrapper_extension = default_ext if wrapper_extension.to_s.empty?

  "#{product_name}.#{wrapper_extension}/#{product_module_name}"
end


def custom_unit_test_target_host_app_path(pods_dir, test_host)
    puts "-> Start modify build settings"

    pods_proj = Xcodeproj::Project.open(File.join(pods_dir, 'Pods.xcodeproj'))

    dev_pods_group = pods_proj.main_group.find_subpath('Development Pods')

    dev_pods_group.children.each do |dev_pods_item|
        dev_pod_proj_path = dev_pods_item.path
        
        unless dev_pod_proj_path.start_with?('/')
            dev_pod_proj_path = File.join(pods_dir, dev_pods_item.path)
        end

        dev_pod_proj = Xcodeproj::Project.open(dev_pod_proj_path)
        dev_pod_proj.targets.each do |target|
            next unless target.name == "#{dev_pods_item.name}-Unit-Tests" || target.name == "#{dev_pods_item.name}-TestsResource"
            puts 'test_target_name = ' + target.name
            target.build_configurations.each do |config|
                config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Ecosystem.app/Ecosystem"
                config.build_settings["OTHER_LDFLAGS"] = ""
                dev_pod_proj.save
            end
        end
    end
    puts "-> End modify build settings"

end

# 修改 OPUnitTestFoundation 编译配置，使其可以直接依赖XCTest
def custom_unit_test_search_paths(installer)
    installer.generated_projects.each do |project|
    if project.project_name == 'OPUnitTestFoundation'
        project.build_configurations.each do |config|
        next unless config.name != 'Release'
        log_ok "configUnitTest modify OPUnitTestFoundation #{config.name}'s build_settings ENABLE_TESTING_SEARCH_PATHS"
        config.build_settings['ENABLE_TESTING_SEARCH_PATHS'] = 'YES'
        end
    end
    end
end

def log_ok(msg)
  puts "[unit test] \e[32m#{msg}\e[0m"
end