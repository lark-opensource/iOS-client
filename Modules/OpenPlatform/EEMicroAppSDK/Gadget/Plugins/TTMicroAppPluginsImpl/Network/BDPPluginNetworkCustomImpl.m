//
//  BDPPluginNetworkCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yin on 2018/12/23.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "BDPPluginNetworkCustomImpl.h"
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <ECOInfra/EMANetworkManager.h>
#import <ECOInfra/EMANetworkMonitor.h>
#import <ECOInfra/EMANetworkRequestManager.h>
#import "EMAAppEngine.h"
#import <OPFoundation/EMADebugUtil.h>
#import <TTReachability/TTReachability.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPNetworkProtocol.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPVersionManager.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

NSString * const kEEMicroAppNetworkPlatform = @"/iOS";
static NSString *kEEJsSDKVersion;

@interface BDPPluginNetworkCustomImpl ()

@end

@implementation BDPPluginNetworkCustomImpl

+ (id<BDPBasePluginDelegate>)sharedPlugin {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self networkPluginBugfixFGDisabled]) {
            instance = [super sharedPlugin];
        } else {
            instance = [[self alloc] init];
        }
        
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.customNetworkManager = [[EMANetworkRequestManager alloc] init];
    }
    return self;
}

#pragma mark - referer & agent

- (NSString *)bdp_customReferWithUniqueID:(BDPUniqueID*)uniqueID
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    BDPModel *model = common.model;
    NSString *jssdkVersion = !BDPIsEmptyString([BDPVersionManager localLibVersionString]) ? [NSString stringWithFormat:@"%@%@", @"/", [BDPVersionManager localLibVersionString]]: @"";
    NSString *appVersion = !BDPIsEmptyString(model.version) ? [NSString stringWithFormat:@"%@%@", @"/", model.version]: @"";
    // serviceRefererURL jssdk版本 应用版本
    return [NSString stringWithFormat:@"%@%@%@%@", BDPSDKConfig.sharedConfig.serviceRefererURL, kEEMicroAppNetworkPlatform, jssdkVersion, appVersion];
}

+ (NSString *)getJsSDKVersionString {
    if (kEEJsSDKVersion == nil) {
        kEEJsSDKVersion = [NSString stringWithFormat:@"EEMicroApp/%@", [BDPVersionManager localLibVersionString]];
    }
    return kEEJsSDKVersion;
}

+ (NSString *)getCustomUserAgentString {
    static NSString *kEECustomUserAgent;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *ua = [BDPUserAgent getOriginUserAgentString];
        NSString *appName = [BDPUserAgent getAppNameAndVersionString];
        NSString *jsSDKVersion = [BDPPluginNetworkCustomImpl getJsSDKVersionString];
        NSArray<NSString *> *appInfos = [appName componentsSeparatedByString:@"/"];
        if([appInfos count] == 2 && [ua containsString:[NSString stringWithFormat:@"%@/", appInfos[0]]]) {
            kEECustomUserAgent = [NSString stringWithFormat:@"%@ %@", ua, jsSDKVersion];
        }
        else {
            kEECustomUserAgent = [NSString stringWithFormat:@"%@ %@ %@", ua, appName, jsSDKVersion];
        }
    });
    return kEECustomUserAgent;
}

- (NSString *)bdp_customUserAgent {
    return [BDPPluginNetworkCustomImpl getCustomUserAgentString];
}

#pragma mark - network request

- (NSURLSession *)bdp_sharedSession {
    return EMANetworkManager.shared.urlSession;
}

- (BOOL)bdp_isNetworkTransmitOverRustChannel {
    return [[EMANetworkManager shared] isNetworkTransmitOverRustChannel];
}

- (NSDictionary *)bdp_rustMetricsForTask:(NSURLSessionTask *)task {
    return [EMANetworkMonitor getRustMetricsForTask:task];
}

- (BOOL)bdp_HTTPShouldHandleCookies {
    return YES;
}

-(NSString *)bdp_openAppInterfaceDomain{
    return EMAAppEngine.currentEngine.config.domainConfig.openAppInterface;
}


#pragma mark - WebImage
- (void)bdp_setImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder {
    [imageView ema_setImageWithUrl:url placeHolder:placeholder];
}

@end
