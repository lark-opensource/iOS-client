//
//  EMADebugUtil.h
//  EEMicroAppSDK
//
//  Created by 殷源 on 2018/10/28.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class EMADebugConfig;

extern NSString * const kEMADebugConfigIDClearMicroAppProcesses;
extern NSString * const kEMADebugConfigIDClearMicroAppFileCache;
extern NSString * const kEMADebugConfigIDClearMicroAppFolders;
extern NSString * const kEMADebugConfigIDClearH5ApppFolders; 
extern NSString * const kEMADebugConfigIDClearJSSDKFileCache;
extern NSString * const kEMADebugConfigIDUseSpecificJSSDKURL;
extern NSString * const kEMADebugConfigIDSpecificJSSDKURL;
extern NSString * const kEMADebugConfigIDDoNotGrayApp;
extern NSString * const kEMADebugConfigIDForceUpdateJSSDK;
extern NSString * const kEMADebugConfigIDForceColdStartMicroApp;
extern NSString * const kEMADebugConfigIDUseStableJSSDK;
extern NSString * const kEMADebugConfigIDDoNotCompressJS;
extern NSString * const kEMADebugConfigIDOpenAppByID;
extern NSString * const kEMADebugConfigIDOpenAppByIPPackage;
extern NSString * const kEMADebugConfigIDOpenAppBySchemeURL;
extern NSString * const kEMADebugConfigIDOpenAppDemo;
extern NSString * const kEMADebugConfigIDUseBuildInJSSDK;
extern NSString * const kEMADebugConfigIDShowJSSDKUpdateTips;
extern NSString * const kEMADebugConfigIDDisableDebugTool;
extern NSString * const kEMADebugConfigIDChangeHostSessionID;
extern NSString * const kEMADebugConfigIDGetHostSessionID;
extern NSString * const kEMADebugConfigIDUseAmapLocation;
extern NSString * const kEMADebugConfigIDDisableAppCharacter;
extern NSString * const kEMADebugConfigIDEnableDebugLog;
extern NSString * const kEMADebugConfigIDEnableLaunchTracing;
extern NSString * const kEMADebugConfigIDForcePrimitiveNetworkChannel;
extern NSString * const kEMADebugConfigAppDemoUrl;
extern NSString * const kEMADebugConfigIDClearPermission;
extern NSString * const kEMADebugConfigIDClearCookies;
extern NSString * const kEMADebugConfigIDEnableRemoteDebugger;
extern NSString * const kEMADebugConfigIDRemoteDebuggerURL;
extern NSString * const kEMADebugH5ConfigIDAppID;
extern NSString * const kEMADebugH5ConfigIDLocalH5Address;
extern NSString * const kEMADebugConfigIDRecentOpenURL;
extern NSString * const kEMADebugConfigUploadEvent;
extern NSString * const kEMADebugConfigForceOverrideRequestID;
extern NSString * const kEMADebugConfigForceOpenAppDebug;
extern NSString * const kEMADebugBlockTest;
extern NSString * const kEMADebugConfigDoNotUseAuthDataFromRemote;
extern NSString * const kEEMicroAppDebugSwitch;
extern NSString * const kEMADebugConfigShowMainWindowPerformanceDebugView;
extern NSString * const kEMADebugConfigIDReloadCurrentGadgetPage;
extern NSString * const kEMADebugConfigIDTriggerMemoryWarning;
extern NSString * const kEMADebugConfigIDWorkerDonotUseNetSetting;
extern NSString * const kEMADebugConfigIDUseNewWorker;
extern NSString * const kEMADebugConfigIDUseVmsdk;
extern NSString * const kEMADebugConfigIDUseVmsdkQjs;
extern NSString * const kEMADebugConfigIDShowWorkerTypeTips;
extern NSString * const kEMADebugConfigIDShowBlockPreviewUrl;
extern NSString * const kEMADebugBlockDetail;

extern NSString * const kEMADebugConfigIDUseSpecificBlockJSSDKURL;
extern NSString * const kEMADebugConfigIDSpecificBlockJSSDKURL;
extern NSString * const kEMADebugConfigIDOPAppLaunchDataDeleteOld;
extern NSString * const kEMADebugConfigMessageCardDebugTool;

typedef enum : NSUInteger {
    EMADebugConfigTypeNone,
    EMADebugConfigTypeBool,
    EMADebugConfigTypeString
} EMADebugConfigType;

@interface EMADebugUtil : NSObject

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, EMADebugConfig *> *debugConfigs;
@property (nonatomic, assign) BOOL usedDebugApp; // 是否使用过调试版本小程序

+ (instancetype)sharedInstance;

- (EMADebugConfig *)debugConfigForID:(NSString *)configID;

//- (void)clearMicroAppProcesses; // 清理所有小程序进程
//- (void)clearMicroAppFileCache; // 清理所有小程序文件缓存
////清理H5应用文件信息
//- (void)clearH5AppFolders;
///// 清理所有小程序文件夹
//- (void)clearMicroAppFolders;
//- (void)clearJSSDKFileCache;    // 清理JSSDK文件缓存
//- (void)checkJSSDKDebugConfig;  // 检查JSSDK配置变更
//- (void)checkBlockJSSDKDebugConfig:(BOOL)needExit; // 检查block js sdk配置变更
//- (void)clearMicroAppPermission;// 清理权限
///// 清理cookies
//- (void)clearAppAllCookies;
//- (void)checkAndSetDebuggerConnection;  //检查设置log连接
//
//-(void)reloadCurrentGadgetPage;
//-(void)triggerMemorywarning;

/// 更新debug开关配置
- (void)updateDebug;

@end

@interface EMADebugConfig : NSObject

@property (nonatomic, assign) EMADebugConfigType configType;
@property (nonatomic, copy) NSString *configID;
@property (nonatomic, copy) NSString *configName;
@property BOOL boolValue;
@property NSString *stringValue;
@property (nonatomic, assign, readonly) BOOL noCache;  // 是否不使用持久化缓存

+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType;
+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType defaultValue:(id)defaultValue;
+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType defaultValue:(id)defaultValue noCache:(BOOL)noCache;

@end
