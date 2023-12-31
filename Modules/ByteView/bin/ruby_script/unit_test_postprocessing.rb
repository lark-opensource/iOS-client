require 'pathname'
require 'xcodeproj'
require 'cocoapods'
require 'lark/project/environment'

# Assume that PRODUCT_NAME, PRODUCT_MODULE_NAME and WRAPPER_EXTENSION of
# 'Debug' configuration are the same as other configurations
def get_executable_path(project_file, target_name, default_ext)
  xc_project = Xcodeproj::Project.open(project_file)
  xc_target = xc_project.targets.find do |target|
    target.name == target_name
  end
  if xc_target.nil?
    raise "Error: target '#{target_name}' does not exist in " \
          "project '#{project_file}'"
  end

  configuration_name = 'Debug'
  build_setting = xc_target.build_settings(configuration_name)
  if build_setting.nil?
    raise "Error: configuration '#{configuration_name}' does not exist in " \
          "target '#{target_name}'"
  end

  product_name = build_setting['PRODUCT_NAME']
  product_name = target_name if product_name.to_s.empty?

  wrapper_extension = build_setting['WRAPPER_EXTENSION']
  wrapper_extension = default_ext if wrapper_extension.to_s.empty?

  product_module_name = build_setting['PRODUCT_MODULE_NAME']
  product_module_name = product_name if product_module_name.to_s.empty?

  "#{product_name}.#{wrapper_extension}/#{product_module_name}"
end

def revise_xctest_targets(pods_dir, test_host)
  Pod::UI.message('- Trying to revise configuration of unit test targets') do
    pods_project_file = File.join(pods_dir, 'Pods.xcodeproj')
    return unless File.exist?(pods_project_file)

    Pod::UI.message("- Trying to retrieve 'Development Pods'") do
      pods_project = Xcodeproj::Project.open(pods_project_file)
      dev_pods_group = pods_project.main_group.find_subpath('Development Pods')
      dev_pods_group.children.each do |dev_pods_item|
        _do_revise_xctest_targets(pods_dir, dev_pods_item, test_host)
      end
    end
  end
end

def revise_host_project(project_file, target_name, scheme_name)
  Pod::UI.message('- Trying to revise configuration of host project ' \
                  'for unit test') do
    return unless _need_run_unit_test
    return unless File.exist?(project_file)

    project = Xcodeproj::Project.open(project_file)
    _revise_debug_information_format(project, target_name)
    _enable_xctest_code_coverage(project, scheme_name)
    project.save
  end
end

def _do_revise_xctest_targets(pods_dir, dev_pods_item, test_host)
  lark_env_internal = Lark::Project::Environment.instance

  dev_pod_project_path = dev_pods_item.path
  unless dev_pod_project_path.start_with?('/')
    dev_pod_project_path = File.join(pods_dir, dev_pods_item.path)
  end

  Pod::UI.message('- Trying to revise xctest target ' \
                  "in '#{dev_pod_project_path}'") do
    dev_pod_project = Xcodeproj::Project.open(dev_pod_project_path)
    dev_pod_project.targets.each do |target|
      next unless target.name == "#{dev_pods_item.name}-Unit-Tests"

      Pod::UI.message('- Found xctest target ' \
                      "'#{dev_pods_item.name}/#{target.name}'") do
        _revise_xctest_build_config(target, test_host)

        if lark_env_internal.local? && _need_show_unit_test_target
          _make_scheme_visible(dev_pod_project, target)
        end
      end
    end
    dev_pod_project.save
  end
end

def _revise_xctest_build_config(target, test_host)
  Pod::UI.message('- Revise build settings')
  target.build_configurations.each do |config|
    config.build_settings['TEST_HOST'] = test_host
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    config.build_settings['OTHER_LDFLAGS'] = ''
  end
end

def _revise_debug_information_format(project, target_name)
  Pod::UI.message('- Trying to set DEBUG_INFORMATION_FORMAT ' \
                  'to dwarf-with-dsym') do
    project.targets.each do |target|
      next unless target.name == target_name

      Pod::UI.message("- Revise target '#{target_name}'")
      target.build_configurations.each do |config|
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      end
    end
  end
end

def _enable_xctest_code_coverage(project, scheme_name)
  Pod::UI.message('- Trying to enable code coverage') do
    shared_schemes_dir = Xcodeproj::XCScheme.shared_data_dir(project.path)
    xcscheme_file = "#{shared_schemes_dir}/#{scheme_name}.xcscheme"
    return unless File.exist?(xcscheme_file)

    Pod::UI.message("- Revise xcscheme '#{xcscheme_file}'")
    xcscheme = Xcodeproj::XCScheme.new(xcscheme_file)
    attrs = xcscheme.test_action.xml_element.attributes

    # Remove attr `onlyGenerateCoverageForSpecifiedTargets`
    attribute = attrs.get_attribute('onlyGenerateCoverageForSpecifiedTargets')
    attribute&.remove

    # Add attr `codeCoverageEnabled`
    xcscheme.test_action.code_coverage_enabled = true

    xcscheme.save!
  end
end

def _need_run_unit_test
  ENV['NEED_RUN_UNIT_TEST'].to_s == 'true'
end

# These two methods are for testing purpose in local environment
def _make_scheme_visible(project, target)
  Pod::UI.message("- Make scheme of '#{target.name}' visible")
  schemes_dir = Xcodeproj::XCScheme.user_data_dir(project.path)
  management_file = "#{schemes_dir}/xcschememanagement.plist"
  management = Xcodeproj::Plist.read_from_path(management_file)
  management['SchemeUserState']["#{target.name}.xcscheme"]['isShown'] = true
  Xcodeproj::Plist.write_to_path(management, management_file)
end

def _need_show_unit_test_target
  ENV['NEED_SHOW_UNIT_TEST_TARGET'].to_s == 'true'
end
