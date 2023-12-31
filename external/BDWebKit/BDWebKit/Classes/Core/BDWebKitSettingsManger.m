//
//  BDWebKitSettingsManger.m
//  BDWebKit
//
//  Created by wealong on 2020/3/6.
//

#import "BDWebKitSettingsManger.h"
#import <objc/message.h>

static Class<BDWebKitSettingsDelegate> kSettingsDelegate;

@implementation BDWebKitSettingsManger

+ (void)setSettingsDelegate:(Class<BDWebKitSettingsDelegate>)settingsDelegate {
    kSettingsDelegate = settingsDelegate;
}

+ (Class<BDWebKitSettingsDelegate>)settingsDelegate {
    return kSettingsDelegate;
}

// 我试过用宏来解决代码重复的问题，最后发现还是这样比较香
#pragma mark - Fix Crash

+ (BOOL)bdFixWKWebViewSchemeTaskCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKWebViewSchemeTaskCrash];
    } else {
        return NO;
    }
}

+ (BOOL)bdWKWebViewFixEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdWKWebViewFixEnable];
    } else {
        return YES;
    }
}

+ (BOOL)bdValidPointerCheckEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdValidPointerCheckEnable];
    } else {
        return YES;
    }
}

+ (BOOL)bdValidObjectCheckEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdValidObjectCheckEnable];
    } else {
        return YES;
    }
}

+ (BOOL)bdFixWebViewBackGroundTaskHangEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWebViewBackGroundTaskHangEnable];
    } else {
        return YES;
    }
}

+ (BOOL)bdFixWebViewBackGroundTaskAfterReleaseEnable{
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWebViewBackGroundTaskAfterReleaseEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdFixWebViewBackGroundNotifyHangEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWebViewBackGroundNotifyHangEnable];
    } else {
        return YES;
    }
}

+ (BOOL)bdFixWebViewBackGroundNotifyTimeOutEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWebViewBackGroundNotifyTimeOutEnable];
    } else {
        return YES;
    }
}

+ (CGFloat)bdFixWebViewBackGroundTaskTimeout {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWebViewBackGroundTaskTimeout];
    } else {
        return 2;
    }
}

+ (NSInteger)bdFixProcessTerminateCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixProcessTerminateCrash];
    } else {
        return 0;
    }
}

+ (BOOL)bdFixRequestURLCrashEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixRequestURLCrashEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdFixDelegateDeallocCrashEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixDelegateDeallocCrashEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdFixBlobCrashEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixBlobCrashEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdFixWKScriptMessageCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKScriptMessageCrash];
    }
    else {
        return NO;
    }
}

+ (BOOL)bdFixWKReleaseEarlyCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKReleaseEarlyCrash];
    }
    else {
        return NO;
    }
}

+ (BOOL)bdFixWKRecoveryAttempterCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKRecoveryAttempterCrash];
    }
    else {
        return NO;
    }
}

+ (BOOL)bdFixWKReloadFrameErrorRecoveryAttempter {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKReloadFrameErrorRecoveryAttempter];
    }
    else {
        return NO;
    }
}

+ (float)bdFixWKReleaseEarlyCrashKeeperTs {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixWKReleaseEarlyCrashKeeperTs];
    }
    else {
        return 1.0;
    }
}

+ (BOOL)bdFixAddUpdateCrash {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixAddUpdateCrash];
    } else {
        return NO;
    }
}

#pragma mark - seclink
+ (BOOL)bdInSeclinkWhitelist:(NSURL*)url {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdInSeclinkWhitelist:url];
    } else {
        return NO;
    }
}

#pragma mark - adblock

+ (BOOL)bdAdblockEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdAdblockEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdUserSettingADBlockEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdUserSettingADBlockEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdAdblockPrecompileEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdAdblockPrecompileEnable];
    } else {
        return NO;
    }
}

+ (NSArray <NSString *>*_Nonnull)bdAdblockDomainWhiteList {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdAdblockDomainWhiteList];
    } else {
        return @[];
    }
}

#pragma mark - XDebugger

+ (BOOL)bdXDebuggerEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdXDebuggerEnable];
    } else {
        return NO;
    }
}

#pragma mark - Offline

+ (NSArray <NSString *>*_Nonnull)skipSSLCertificateList {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] skipSSLCertificateList];
    } else {
        return @[];
    }
}

+ (BOOL)checkOfflineWholeLife:(NSString *_Nullable)url {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] checkOfflineWholeLife:url];
    } else {
        return NO;
    }
}

+ (BOOL)checkOfflineChannelInterceptor {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] checkOfflineChannelInterceptor];
    } else {
        return YES;
    }
}

+ (BOOL)checkOfflineChannelInterceptorInjectJS {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] checkOfflineChannelInterceptorInjectJS];
    } else {
        return NO;
    }
}

#pragma mark - Falcon

+ (BOOL)useTTNetForFalcon {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:@selector(useTTNetForFalcon)]) {
        return [[BDWebKitSettingsManger settingsDelegate] useTTNetForFalcon];
    } else {
        return NO;
    }
}

+ (NSArray *_Nullable)useTTNetForFalconWhiteList {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:@selector(useTTNetForFalconWhiteList)]) {
        return [[BDWebKitSettingsManger settingsDelegate] useTTNetForFalconWhiteList];
    } else {
        return nil;
    }
}

+ (BOOL)allowRecursiveRequestFlagForDefaultSchemaHandler {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] allowRecursiveRequestFlagForDefaultSchemaHandler];
    } else {
        return NO;
    }
}

#pragma mark - TTNet

+ (BOOL)bdTTNetOriginOpitimise {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetOriginOpitimise];
    } else {
        return NO;
    }
}

+ (BOOL)bdTTNetFixRedirect {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetFixRedirect];
    } else {
        return NO;
    }
}

+ (BOOL)bdFixSyncAjaxCrashEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixSyncAjaxCrashEnable];
    } else {
        return NO;
    }
}

+ (CGFloat)bdFixTTNetTimeout {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdFixTTNetTimeout];
    } else {
        return 30;
    }
}

+ (BOOL)bdEnablePrefetch {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdEnablePrefetch];
    } else {
        return NO;
    }
}

+ (BOOL)bdTTNetCacheControlEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetCacheControlEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdTTNetAutoBlockListEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetAutoBlockListEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdTTNetBlobAutoBlackEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetBlobAutoBlackEnable];
    } else {
        return NO;
    }
}

+ (NSArray *_Nullable)bdTTNetAutoBlockListErrorStatusCode {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetAutoBlockListErrorStatusCode];
    } else {
        return @[@(404),@(502)];
    }
}

+ (BOOL)useNewBlankCheck {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] useNewBlankCheck];
    } else {
        return YES;
    }
}

+ (BOOL)bdTTNetFixCors {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetFixCors];
    } else {
        return YES;
    }
}

+ (BOOL)bdTTNetAvoidNoResponseException {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdTTNetAvoidNoResponseException];
    } else {
        return NO;
    }
}

+ (BOOL)bdCookieSecureEnable {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdCookieSecureEnable];
    } else {
        return NO;
    }
}

+ (BOOL)bdSyncCookieForMainFrameResponse {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdSyncCookieForMainFrameResponse];
    } else {
        return NO;
    }
}

+ (BOOL)bdAddAcceptLanguageHeaderIfNeeded {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdAddAcceptLanguageHeaderIfNeeded];
    } else {
        return NO;
    }
}

+ (NSArray<NSString *> *)bdSecureCookieList {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdSecureCookieList];
    } else {
        return @[];
    }
}

#pragma mark - PIA

+ (NSInteger)bdPIAJSEngine {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdPIAJSEngine];
    } else {
        return eBDPIAJSEngineQuickJS;
    }
}

#pragma mark - Track
+ (BOOL)bdReportLastWebURL {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdReportLastWebURL];
    } else {
        return NO;
    }
}

#pragma mark - UA
+ (BOOL)bdEnableUAFetch {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdEnableUAFetch];
    } else {
        return NO;
    }
}

+ (BDWebViewUAFetchTime)bdUAFetchTime {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdUAFetchTime];
    } else {
        return BDWebViewUAFetchTimeMainAsync;
    }
}

+ (BOOL)bdEnableUAFetchWithKV {
    if ([[BDWebKitSettingsManger settingsDelegate] respondsToSelector:_cmd]) {
        return [[BDWebKitSettingsManger settingsDelegate] bdEnableUAFetchWithKV];
    } else {
        return NO;
    }
}
@end
