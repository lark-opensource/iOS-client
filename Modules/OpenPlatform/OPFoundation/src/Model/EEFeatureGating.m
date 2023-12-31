//
//  EEFeatureGating.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/24.
//

#import "EEFeatureGating.h"

NSString *const EEFeatureGatingKeyGadgetEnablePublishLog = @"openplatform.gadget.log_bridge_publish";
NSString *const EEFeatureGatingKeyGadgetWebAppApiMonitorReport = @"gadget.web_app.api.monitor_report";
NSString *const EEFeatureGatingKeyGadgetOpenAppBadge = @"gadget.open_app.badge";
NSString *const EEFeatureGatingKeyGadgetDisablePluginManager = @"openplatform.disable.new.pluginapi";
NSString *const EEFeatureGatingKeyGadgetEnableSlideExitOnHitDebugPoint = @"openplatform.gadget.realmachine_debug.slide_exit";
NSString *const EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor = @"openplatform.gadget.api_use_jssdk_monitor";
NSString *const EEFeatureGatingKeyGadgetIos15InputKeyboardWakeUpAfterDelay = @"openplatform.gadget.input.ios15.keyboard.wakeupafterdelay";
NSString *const EEFeatureGatingKeyGadgetWebComponentCheckdomain = @"openplatform.webcomponent.check.safedomain";
NSString *const EEFeatureGatingKeyGadgetWebComponentIDEDisableCheckDomain = @"openplatform.web.ide_disable_domain_check";
NSString *const EEFeatureGatingKeyGadgetWebComponentDoubleCheck = @"openplatform.webcomponent.safedomain.doublecheck";
NSString *const EEFeatureGatingKeyGadgetWebComponentDomainOpen = @"openplatform.webcomponent.safedomain.open.enable";
NSString *const EEFeatureGatingKeyGadgetWebComponentIgnoreInterrupted = @"openplatform.webcomponent.safedomain.ingore.interrupt";
NSString *const EEFeatureGatingKeyGadgetWebComponentGlobalEnableURL = @"lark.developer_console.enable_glob_in_gadget_url.native";
NSString *const EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor = @"gadget.worker.api_use_jssdk_monitor";
NSString *const EEFeatureGatingKeyGadgetEnableH5NativeBufferEncode = @"openplatform.h5.nativebuffer.encode";
NSString *const EEFeatureGatingKeyGadgetWorkerModuleDisable = @"gadget.worker.module_disable";
NSString *const EEFeatureGatingKeyGadgetWorkerCheckOnLaunchEnable = @"gadget.worker.check_update_on_launch.enable";
NSString *const EEFeatureGatingKeyGadgetNativeComponentEnableMap = @"gadget.native_component.enable.map";
NSString *const EEFeatureGatingKeyGadgetNativeComponentEnableVideo = @"gadget.native_component.enable.video";
NSString *const EEFeatureGatingKeyGadgetVideoMetalEnable = @"openplatform.gadget.video.metal.enable";
NSString *const EEFeatureGatingKeyGadgetVideoEnableCorrentRealClock = @"openplatform.gadget.video_component_enable_correct_real_clock";
NSString *const EEFeatureGatingKeyGadgetVideoDisableAutoPause = @"openplatform.gadget.video_component_disable_auto_pause";
NSString *const EEFeatureGatingKeyGetUserInfoAuth = @"openplatform.scope.add_user_info";
NSString *const EEFeatureGatingKeyGetAddAuthTextLength = @"openplatform.scope.add_authtext_length";
NSString *const EEFeatureGatingKeyNewScopeMapRule = @"openplatform.setting.new_scope_map_rule";
NSString *const EEFeatureGatingKeyChooseLocationSupportWGS84 = @"openplatform.api.choose_location_support_wgs84";
NSString *const EEFeatureGatingKeyTransferMessageFormateConsistent = @"client.open_platform.gadget.web-view.transfer_msg.format";
NSString *const EEFeatureGatingKeyNativeComponentDisableShareHitTest = @"gadget.native_component.disable.share_hit_test";
NSString *const EEFeatureGatingKeyGadgetTabBarRelaunchFixDisable = @"openplatform.microapp.tabbar_relaunch_fix_disable";
NSString *const EEFeatureGatingKeyEnableAppLinkPathReplace = @"openplatform.gadget.enable_applink_path_replace";
NSString *const EEFeatureGatingKeyBlockJSSDKUpdate = @"openplatform.block.jssdk.update";
NSString *const EEFeatureGatingKeyBlockJSSDKFixCopyBundleIssue = @"openplatform.block.jssdk.fix_copy_bundle_issue";
NSString *const EEFeatureGatingKeyBridgeCallbackArrayBuffer = @"openplatfrom.bridge.callbackarraybuffer.enable";
NSString *const EEFeatureGatingKeyBridgeFireEventArrayBuffer = @"openplatfrom.bridge.fireeventarraybuffer.enable";
NSString *const EEFeatureGatingKeyFixMergePackageDownloadTask = @"openplatform.gadget.fix_reuse_package_download_task";
NSString *const EEFeatureGatingKeyScopeBluetoothEnable = @"openplatform.scope.bluetooth.enable";
NSString *const EEFeatureGatingKeyXScreenGadgetEnable = @"openplatform.applink.open_mini_program_with_panel.enable";
NSString *const EEFeatureGatingKeyIGadgetPresentFrameFixEnable = @"openplatform.gadget.present_frame_fix.enable";
NSString *const EEFeatureGatingKeyFixNavigationPushPosition = @"openplatform.gadget.fix_navigationbar_position_on_push";
NSString *const EEFeatureGatingKeyXscreenLayoutFixDisable = @"openplatform.gadget.xscreen.layout.fix.disable";
NSString *const EEFeatureGatingKeyResetFrameFixDisable = @"openplatform.gadget.reset.frame.fix.disable";
NSString *const EEFeatureGatingKeyNativeComponentKeyboardOpt = @"openplatform.component.keyboard.opt";
NSString *const EEFeatureGatingKeyEvadeJSCoreDeadLock = @"openplatform.gadget.evade_jscore_deadlock";
NSString *const EEFeatureGatingKeyBDPPiperRegisterOptDisable = @"openplatform.api.bridge.register.opt.disable";
NSString *const EEFeatureGatingKeyAPINetworkV1PMDisable = @"openplatform.api.network.v1.pm.disable";
NSString *const EEFeatureGatingKeyGadgetTabBarRemoveFixDisable = @"openplatform.microapp.tabbar_remove_fix_disable";
