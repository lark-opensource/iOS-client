Pod::Spec.new do |spec|
  spec.name         = "SKFoundation_Tests"
  spec.version = '5.28.0'
  spec.summary      = "A short description of SKFoundation_Tests."
  spec.homepage     = "http://EXAMPLE/SKFoundation_Tests"
  spec.license      = "MIT"
  spec.authors      = "chenwenhuan.goguhuan"
  spec.source       = { :git => "https://xxx.xx.x" }

  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.13'

  spec.default_subspecs = "Core"

  spec.subspec "Core" do |ss|
    ss.source_files = "src/**/*.{h,m,c,cpp,mm,swift}"
    ss.xcconfig = {
      'ENABLE_TESTING_SEARCH_PATHS' => 'YES'
    }
  end

  ######################################################## Autogen by baymax init - start ########################################################
  
  if ENV["BYM_Enable_Baymax"] == "YES"
  
  _configure_test = -> (ss) {
  	ss.source_files = 'SKFoundation_Tests/Tests/src/**/*.{h,m,mm,swift}'
    ss.dependency 'SwiftyJSON'
  	ss.xcconfig = {
      'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
  		'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/Headers/Private"',
  		'SYSTEM_FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PLATFORM_DIR)/Developer/Library/PrivateFrameworks" "$(PLATFORM_DIR)/Developer/Library/Frameworks"',
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/SKFoundation"',
  	}
  }
  
  spec.subspec 'Tests' do |ss|
  	_configure_test.call(ss)
  end
  
  if ENV["ROCK_PACKAGE_PROJECT_ID"] || ENV["ROCK_PACKAGE_REF_BRANCH"]
  else
  spec.test_spec '_Tests' do |ss|
  	_configure_test.call(ss)
  end
  end
  
  spec.subspec '_Dummy' do |ss|
  	ss.source_files = 'SKFoundation_Tests/Tests/_Dummy/SKFoundation_TestsDummy.m'
  end
  
  end
  
  ######################################################## Autogen by baymax init - end ########################################################
end