//
//  TSPKPushOfUNUserNotificationCenterPipeline.m
//
//  Created by Bytedance on 2022/9/20.
//

#import "TSPKPushOfUNUserNotificationCenterPipeline.h"
#import "TSPKUtils.h"
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

#import <UserNotifications/UNUserNotificationCenter.h>

@implementation UNUserNotificationCenter (TSPrivacyKitAlbum)

+ (void)tspk_push_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKPushOfUNUserNotificationCenterPipeline class] clazz:self];
}

- (void)tspk_push_requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    NSString *method = NSStringFromSelector(@selector(requestAuthorizationWithOptions:completionHandler:));
    NSString *className = [TSPKPushOfUNUserNotificationCenterPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKPushOfUNUserNotificationCenterPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        if (completionHandler) {
            completionHandler(NO, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_push_requestAuthorizationWithOptions:options completionHandler:completionHandler];
    }
}

@end

@implementation TSPKPushOfUNUserNotificationCenterPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelinePushOfUNUserNotificationCenter;
}

+ (NSString *)dataType {
    return TSPKDataTypePush;
}

+ (NSString *)stubbedClass
{
    if (@available(iOS 10.0, *)) {
        return @"UNUserNotificationCenter";
    }
    return nil;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(requestAuthorizationWithOptions:completionHandler:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 10.0, *)) {
            [UNUserNotificationCenter tspk_push_preload];
        }
    });
}

@end
