# frozen_string_literal: true

# rubocop:disable Metrics

require 'cocoapods'
require 'xcodeproj'
require 'lark/project'
require_relative './lark_assert'

module Pod
  # Extensions about unit test
  class Podfile
    # @param [Pod::Installer] installer
    def lark_unit_test_common_pre_install(installer)
      return unless _in_bits_ci?

      UI.message("[ut_pre_install] disable assert")

      # disable lark_assert
      assert_dir :none

      # disable oc_assert
      installer.pod_targets.each do |pod_target|
        # @type [Pod::PodTarget] pod_target
        attributes_hash = pod_target.root_spec.attributes_hash
        pod_target_xcconfig = (attributes_hash['pod_target_xcconfig'] ||= {})
        # disable oc assert
        pod_target_xcconfig['ENABLE_NS_ASSERTIONS'] = 'NO'
      end
    end

    # @param [Pod::Installer] installer
    # @param [Array<String>] test_pods
    def lark_unit_test_common_post_integrate(installer, test_pods)
      raise '[ut_post_integrate] test_pods should not be empty' if test_pods.empty?

      # treat first aggregate_target as main project
      # @type [Xcodeproj::Project] main_proj. eg: Modules/Messenger/Lark.xcodeproj
      main_proj = installer.aggregate_targets.first&.user_project
      raise '[ut_post_integrate] parse main project failed' if main_proj.nil?

      # treat first target as main target
      # @type [Xcodeproj::Project::PBXNativeTarget] main_ptarget
      main_target = main_proj.targets.first
      raise '[ut_post_integrate] parse main target failed' if main_target.nil?

      if _in_bits_ci?
        # debug inforamation format
        main_target.build_configurations.each do |config|
          config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
        end
        # set coverage in scheme
        shared_schemes_dir = Xcodeproj::XCScheme.shared_data_dir(main_proj.path)
        scheme = ENV['UT_PROJ_SCHEME'] || ''
        unless scheme.empty?
          UI.message '[ut_post_integrate] will set coverage in scheme'
          xcscheme_file = "#{shared_schemes_dir}/#{scheme}.xcscheme"
          xcscheme = Xcodeproj::XCScheme.new(xcscheme_file)
          attrs = xcscheme.test_action.xml_element.attributes

          # Remove attr `onlyGenerateCoverageForSpecifiedTargets`
          attribute = attrs.get_attribute('onlyGenerateCoverageForSpecifiedTargets')
          attribute&.remove
          # Add attr `codeCoverageEnabled`
          xcscheme.test_action.code_coverage_enabled = true
          xcscheme.save!
        else
          UI.warn '[ut_post_integrate] missing scheme'
        end
      end

      # find test_host
      # @type [String] test_host
      test_host = _find_test_host(main_target)
      UI.message "[ut_post_integrate] handle test targets with test_host: #{test_host}"

      test_pods.each do |pod|
        proj_path = installer.sandbox.pod_target_project_path(pod)
        xc_proj = Xcodeproj::Project.open(proj_path)

        targets_hash = _find_proj_test_targets(xc_proj)
        test_targets = targets_hash[:test_targets]
        test_targets.each do |target|
          UI.message "[ut_post_integrate] set build settings for #{target.name}"
          target.build_configurations.each do |config|
            config.build_settings['TEST_HOST'] = test_host
            config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
            config.build_settings['OTHER_LDFLAGS'] = ''
          end
        end

        test_bundle_targets = targets_hash[:test_bundle_targets]
        test_bundle_targets.each do |target|
          UI.message "[ut_post_integrate] clean build settings for #{target.name}"
          target.build_configurations.each do |config|
            config.build_settings['OTHER_LDFLAGS'] = ''
          end
        end

        xc_proj.save
      end
    end

    private

    def _in_bits_ci?
      (ENV['NEED_RUN_UNIT_TEST'] || '') == 'true'
    end

    # @return [String]
    def _find_test_host(main_target)
      configuration_name = 'Debug'
      build_setting = main_target.build_settings(configuration_name)
      if build_setting.nil?
        raise "Error: configuration '#{configuration_name}' does not exist in " \
              "target '#{main_target.name}'"
      end

      product_name = build_setting['PRODUCT_NAME']
      product_name = main_target.name if product_name.to_s.empty?

      wrapper_extension = build_setting['WRAPPER_EXTENSION']
      wrapper_extension = 'app' if wrapper_extension.to_s.empty?

      product_module_name = build_setting['PRODUCT_MODULE_NAME']
      product_module_name = product_name if product_module_name.to_s.empty?

      test_host_relative_path = "#{product_name}.#{wrapper_extension}/#{product_module_name}"
      "$(BUILT_PRODUCTS_DIR)/#{test_host_relative_path}"
    end

    # Find all test targets for {xc_proj}
    #
    # @param [Xcodeproj] xc_proj
    # @return {
    #   'test_targets': Array<Xcodeproj::Project::PBXNativeTarget>,
    #   'test_bundle_targets': Array<Xcodeproj::Project::PBXNativeTarget>
    # }
    def _find_proj_test_targets(xc_proj)
      # find all test targets
      # @type test_targets [Array<Xcodeproj::Project::PBXNativeTarget>]
      test_targets = xc_proj.targets.filter do |tg|
        next false unless tg.is_a?(Xcodeproj::Project::PBXNativeTarget)

        tg.symbol_type == :unit_test_bundle
      end

      # NOTE: 没有更好的寻找 test bundle target 的姿势，此处通过 dependencies 寻找...
      # @type [Array<Xcodeproj::Project::PBXNativeTarget>] test_bundle_targets
      test_bundle_targets = []
      test_targets.each do |tg|
        tg.dependencies.each do |dep|
          dep_tg = dep.target
          next unless dep_tg.is_a?(Xcodeproj::Project::PBXNativeTarget)
          next unless dep_tg.symbol_type == :bundle
          next unless xc_proj.targets.any? { |t| dep_tg.uuid == t.uuid }

          test_bundle_targets << dep_tg
        end
      end
      { 'test_targets': test_targets, 'test_bundle_targets': test_bundle_targets }
    end
  end
end

# rubocop:enable all
