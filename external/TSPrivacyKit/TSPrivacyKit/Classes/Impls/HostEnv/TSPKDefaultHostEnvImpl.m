//
//  TSPKDefaultHostEnvImpl.m
//  Aweme
//
//  Created by admin on 2021/11/6.
//

#import "TSPKDefaultHostEnvImpl.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <TSPrivacyKit/TSPKMonitor.h>
#import "TSPKLogger.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "TSPrivacyKitConstants.h"
#import <TTReachability/TTReachability.h>

@implementation TSPKDefaultHostEnvImpl

#pragma mark - Other auxiliary imp
- (nullable NSString *)urlIfTopIsWebViewController{
    return nil;
}

- (NSDictionary <NSString *, NSDictionary *> *)extraBizInfoWithGuardScene:(NSString *)monitorScene permissionType:(NSString *)permissionType {
    return nil;
}

- (BOOL)isEventBlocked:(NSString *)eventName
{
    if (![HMDUserExceptionTracker sharedTracker].isRunning) {
        return NO;
    }
    
    NSError *error = [[HMDUserExceptionTracker sharedTracker] checkIfAvailableForType:eventName];
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"isEventBlocked error %@", error]];
    
    return error != nil;
}

- (nullable NSString *)userRegion {
    return [[TTNetworkManager shareInstance] userRegion];
}

- (NSDictionary<NSString *,NSString *> *)extraCommonBizInfoWithGuardScene:(NSString *)monitorScene permissionType:(NSString *)permissionType {
    return nil;
}

@end /* TSPKDefaultHostEnvImpl */
