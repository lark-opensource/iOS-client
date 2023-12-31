#
# Be sure to run `pod lib lint KALogin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KALogin'
  s.version          = '0.1.0'
  s.summary          = 'Login SDK for KA'
  s.description      = 'Login SDK for KA'
  s.homepage         = 'https://github.com/Nix/KALogin'
  s.authors = {
    'Nix' => 'wangxin.pro@bytedance.com'
  }

  s.ios.deployment_target = '11.0'

  s.source_files = 'src/**/*'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  
  s.dependency 'LKAppLinkExternal'
  s.dependency 'MBProgressHUD'
  s.dependency 'LKNativeAppExtension'
  s.dependency 'LKNativeAppExtensionAbility'
  s.dependency 'KADemoAssemble'
  
end
