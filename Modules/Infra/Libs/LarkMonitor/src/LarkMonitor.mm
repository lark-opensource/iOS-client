//
//  LarkMonitor.m
//  Lark
//
//  Created by lichen on 2018/10/22.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

#import "LarkMonitor.h"
#import "LKCustomException/LKCException.h"
#import <Heimdallr/HMDTTMonitor.h>
#import <Heimdallr/HMDUserExceptionTracker.h>
#import "NSDictionary+deepCopy.h"
#import <Heimdallr/Heimdallr.h>
#import <Heimdallr/HMDUIFrozenManager.h>
#import <LarkMonitor/LarkMonitor-swift.h>
#import <BDFishhook/BDFishhook.h>
#import <UIKit/UIKit.h>

@implementation LarkMonitor

+(void)setupMonitor:(nonnull NSString *)appID
            appName:(nonnull NSString *)appName
            channel:(nonnull NSString *)channel
           deviceID:(nonnull NSString *)deviceID
             userID:(nullable NSString *)userID
           userName:(nullable NSString *)userName
    crashUploadHost:(nullable NSString *)crashUploadHost
exceptionUploadHost:(nullable NSString *)exceptionUploadHost
userExceptionUploadHost:(nullable NSString *)userExceptionUploadHost
performanceUploadHost:(nullable NSString *)performanceUploadHost
fileUploadHost:(nullable NSString *)fileUploadHost
configHostArray:(nullable NSArray<NSString *> *)configHostArray
{
    HMDInjectedInfo *injectedInfo = [HMDInjectedInfo defaultInfo];
    injectedInfo.appID = appID;
    injectedInfo.installID = appID;
    injectedInfo.channel = channel;
    injectedInfo.appName = appName;
    injectedInfo.deviceID = deviceID;
    injectedInfo.userID = userID;
    injectedInfo.userName = userName;
    injectedInfo.ignorePIPESignalCrash = YES;

    injectedInfo.crashUploadHost = crashUploadHost;
    injectedInfo.exceptionUploadHost = exceptionUploadHost;
    injectedInfo.userExceptionUploadHost = userExceptionUploadHost;
    injectedInfo.performanceUploadHost = performanceUploadHost;
    injectedInfo.fileUploadHost = fileUploadHost;
    injectedInfo.configHostArray = configHostArray;

    open_bdfishhook();
    [[Heimdallr shared] setupWithInjectedInfo:injectedInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFrozenNotification:) name:HMDUIFrozenNotificationDidEnterBackground object:nil];
}

+ (void)receiveFrozenNotification:(NSNotification *)noti {
    if ([noti.object isKindOfClass:[NSDictionary class]] && [self checkWheather_UIParallaxDimmingView:noti.object]) {
        [LarkAllActionLoggerLoad logPerformanceErrorWithError:@"exist _UIParallaxDimmingView course UIFrozen"];
        [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithExceptionType:@"UIFrozen_DimmingView" title:@"" subTitle:@"" customParams:nil filters:nil callback:^(NSError * _Nullable error) {
            exit(0);
        }];
    }
}

+ (BOOL)checkWheather_UIParallaxDimmingView:(NSDictionary *)frozenObjc {
    UIView *targetView = frozenObjc[kHMDUIFrozenKeyTargetView];
    NSString *frozenType = frozenObjc[kHMDUIFrozenKeyType];
    if ([frozenType isEqualToString:@"HitTest"]) {
        for (UIView *view in targetView.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"_UIParallaxDimmingView")]) {
                return YES;
            }
        }
    }
    return NO;
}

+(void)updateUserInfo:(nullable NSString *)userID
             userName:(nullable NSString *)userName
             userEnv:(nullable NSString *)userEnv {
    HMDInjectedInfo *injectedInfo = [HMDInjectedInfo defaultInfo];
    injectedInfo.userID = userID;
    injectedInfo.userName = userName;
    [injectedInfo setCustomFilterValue:userEnv forKey:@"env"];
}

+(void)updateCrashUploadHost:(nullable NSString *)crashUploadHost
         exceptionUploadHost:(nullable NSString *)exceptionUploadHost
     userExceptionUploadHost:(nullable NSString *)userExceptionUploadHost
       performanceUploadHost:(nullable NSString *)performanceUploadHost
              fileUploadHost:(nullable NSString *)fileUploadHost
             configHostArray:(nullable NSArray<NSString *> *)configHostArray {
    HMDInjectedInfo *injectedInfo = [HMDInjectedInfo defaultInfo];
    injectedInfo.crashUploadHost = crashUploadHost;
    injectedInfo.exceptionUploadHost = exceptionUploadHost;
    injectedInfo.userExceptionUploadHost = userExceptionUploadHost;
    injectedInfo.performanceUploadHost = performanceUploadHost;
    injectedInfo.fileUploadHost = fileUploadHost;
    injectedInfo.configHostArray = configHostArray;
}

+(void)startCustomException:(NSDictionary *)config {
    [[LKCException sharedInstance] setupCustomExceptionWithConfig:config];
}

+(void)stopCustomException {
    [[LKCException sharedInstance] stopCustomException];
}

+ (void)trackService:(NSString *)serviceName metric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSDictionary *metricDeep = [metric deepCopy];
    NSDictionary *categoryDeep = [category deepCopy];
    NSDictionary *extraDeep = [extra deepCopy];

    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName metric:metricDeep category:categoryDeep extra:extraDeep];
}

+ (void)immediatelyTrackService:(NSString *)serviceName metric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSDictionary *metricDeep = [metric deepCopy];
    NSDictionary *categoryDeep = [category deepCopy];
    NSDictionary *extraDeep = [extra deepCopy];

    [[HMDTTMonitor defaultManager] hmdUploadImmediatelyTrackService:serviceName metric:metricDeep category:categoryDeep extra:extraDeep];
}

+ (void)trackService:(NSString *)serviceName
              status:(NSInteger)status
               extra:(NSDictionary *)extra {
    [LarkMonitor trackService:serviceName metric:@{@"status": @(status)} category:@{} extra:extra];
}

+ (void)trackService:(NSString *)serviceName
               value:(id)value
               extra:(NSDictionary *)extra {
    [LarkMonitor trackService:serviceName metric:@{} category:@{@"value": value} extra:extra];
}

+ (void)trackService:(NSString *)serviceName attributes:(NSDictionary *)attributes
{
    NSDictionary *deepAttributes = [attributes deepCopy];
    [HMDTTMonitor.defaultManager hmdTrackService:serviceName attributes:deepAttributes];
}

+ (void)trackData:(NSDictionary *)data
       logTypeStr:(NSString *)logType {
    NSDictionary *dic = [data deepCopy];
    [[HMDTTMonitor defaultManager] hmdTrackData:dic logTypeStr:logType];
}

+ (void)addCrashDetectorCallBack:(CrashReportBlock)callBack {
    [[HMDCrashTracker sharedTracker] addCrashDetectCallBack:callBack];
}

@end
