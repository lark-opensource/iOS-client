//
//  BDWebKitSettingsManger.h
//  BDWebKit
//
//  Created by wealong on 2020/3/6.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, eBDPIAJSEngine) { eBDPIAJSEngineQuickJS = 0,
                                             eBDPIAJSEngineJSC = 1,
};

/// 获取系统 UA 时机，性能优化
typedef NS_ENUM(NSInteger, BDWebViewUAFetchTime) {
    BDWebViewUAFetchTimeMainAsync = 0,          // async main queue
    BDWebViewUAFetchTimeMainIdle,               // Main Runloop idle time.
};

@protocol BDWebKitSettingsDelegate <NSObject>

@optional

#pragma mark - Fix Crash

@optional

+ (BOOL)bdFixWKWebViewSchemeTaskCrash;

+ (BOOL)bdWKWebViewFixEnable;

+ (BOOL)bdValidPointerCheckEnable; //

+ (BOOL)bdValidObjectCheckEnable; //

+ (BOOL)bdFixWebViewBackGroundTaskHangEnable; //

+ (BOOL)bdFixWebViewBackGroundTaskAfterReleaseEnable; //

+ (BOOL)bdFixWebViewBackGroundNotifyHangEnable; //

+ (BOOL)bdFixWebViewBackGroundNotifyTimeOutEnable; //

+ (CGFloat)bdFixWebViewBackGroundTaskTimeout; //

+ (NSInteger)bdFixProcessTerminateCrash;

+ (BOOL)bdFixRequestURLCrashEnable;

+ (BOOL)bdFixDelegateDeallocCrashEnable;

+ (BOOL)bdFixBlobCrashEnable;

+ (BOOL)bdFixWKScriptMessageCrash;

+ (BOOL)bdFixWKRecoveryAttempterCrash;

+ (BOOL)bdFixWKReloadFrameErrorRecoveryAttempter;

+ (BOOL)bdFixWKReleaseEarlyCrash;

+ (float)bdFixWKReleaseEarlyCrashKeeperTs;

+ (BOOL)bdFixAddUpdateCrash;

#pragma mark - seclink
+ (BOOL)bdInSeclinkWhitelist:(NSURL *)url;

#pragma mark - adblock

// 是否允许ADBlock生效
+ (BOOL)bdAdblockEnable;

// 用户是否允许ADBlock生效
+ (BOOL)bdUserSettingADBlockEnable;

// 是否使用预编译的规则包
+ (BOOL)bdAdblockPrecompileEnable;

+ (NSArray<NSString *> *_Nonnull)bdAdblockDomainWhiteList;

#pragma mark - XDebugger

+ (BOOL)bdXDebuggerEnable;

#pragma mark - Offline

+ (NSArray<NSString *> *_Nonnull)skipSSLCertificateList;

+ (BOOL)checkOfflineWholeLife:(NSString *_Nullable)url;

+ (BOOL)checkOfflineChannelInterceptor;

+ (BOOL)checkOfflineChannelInterceptorInjectJS;

#pragma mark - Falcon

+ (BOOL)useTTNetForFalcon;

+ (NSArray<NSString *> *_Nullable)useTTNetForFalconWhiteList;

+ (BOOL)allowRecursiveRequestFlagForDefaultSchemaHandler;

#pragma mark - TTNet

+ (BOOL)bdTTNetOriginOpitimise; //

+ (BOOL)bdTTNetFixRedirect; //

+ (BOOL)bdFixSyncAjaxCrashEnable; //

+ (CGFloat)bdFixTTNetTimeout; //

+ (BOOL)bdTTNetCacheControlEnable;

+ (BOOL)bdTTNetAutoBlockListEnable;

+ (BOOL)bdTTNetBlobAutoBlackEnable;

+ (NSArray *_Nullable)bdTTNetAutoBlockListErrorStatusCode;

+ (BOOL)bdEnablePrefetch;

+ (BOOL)useNewBlankCheck;

+ (BOOL)bdTTNetFixCors;

+ (BOOL)bdTTNetAvoidNoResponseException;

+ (BOOL)bdCookieSecureEnable;

+ (BOOL)bdSyncCookieForMainFrameResponse;

+ (NSArray<NSString *> *)bdSecureCookieList;

+ (BOOL)bdAddAcceptLanguageHeaderIfNeeded;

#pragma mark - PIA

+ (NSInteger)bdPIAJSEngine;

#pragma mark - track
+(BOOL)bdReportLastWebURL;

#pragma mark - UA

/// UA 实验开关
+ (BOOL)bdEnableUAFetch;

/// fetch UA 时机
+ (BDWebViewUAFetchTime)bdUAFetchTime;

/// 是否允许通过 WKWebView valueForKey 的方式获取 UA
+ (BOOL)bdEnableUAFetchWithKV;


@end

NS_ASSUME_NONNULL_BEGIN

@interface BDWebKitSettingsManger : NSObject <BDWebKitSettingsDelegate>

@property(strong, nonatomic, class) Class<BDWebKitSettingsDelegate> settingsDelegate;

@end

NS_ASSUME_NONNULL_END
