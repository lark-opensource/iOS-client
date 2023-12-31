//
//  BDPJSContext.m
//  Timor
//
//  Created by CsoWhy on 2018/10/14.
//

#import "BDPJSRuntime.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "BDPTracingManager+Gadget.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPWeakProxy.h>
#import <OPFoundation/BDPAppMetaUtils.h>
#import <OPFoundation/OPAPIFeatureConfig.h>
#import <OPFoundation/EEFeatureGating.h>
#import "BDPPluginUpdateManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "BDPJSRuntimeSettings.h"
#import "BDPGadgetLog.h"
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPTimorClient.h>
#import "BDPDebugMacro.h"
#import <OPFoundation/BDPMonitorEvent.h>

#pragma mark - BDPJSContext

typedef NS_ENUM(NSUInteger, BDPOnUpdateReadySource) {
    BDPOnUpdateReadyFromUnknowSource = 0,
    BDPOnUpdateReadyFromUpdateManager,
    BDPOnUpdateReadyFromAyncUpdate
};

NSString * const kBDPJSRuntimeUpdateStrategyControlTimestamp = @"kBDPJSRuntimeUpdateStrategyControlTimestamp";

@interface OPAppUniqueID (UpdateStrategyControl)
-(NSString *)maxAgeForUpdateStrategyControl;
-(NSString *)maxAgeForUpdateStrategyControlWithoutUniqueId;
@end


@implementation OPAppUniqueID (UpdateStrategyControl)
//带AppID纬度的uniqueKey
-(NSString *)maxAgeForUpdateStrategyControl
{
    return [[self fullString] stringByAppendingFormat:@"_%@", [OPAppUniqueID userDefaultKeyWithoutUniqueId]];
}

//用户+租户纬度的uniqueKey
+(NSString *)userDefaultKeyWithoutUniqueId
{
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    NSString * userId = @"";
    if ([userPlugin respondsToSelector:@selector(bdp_sessionId)]) {
        userId = [[userPlugin bdp_userId] bdp_md5String];
    }
    NSString * encyptTenantId = @"";
    if ([userPlugin respondsToSelector:@selector(bdp_encyptTenantId)]) {
        encyptTenantId = [userPlugin bdp_encyptTenantId];
    }
    NSString * maxAgeKey = [NSString stringWithFormat:@"%@_%@_%@", userId, encyptTenantId,kBDPJSRuntimeUpdateStrategyControlTimestamp];
    return maxAgeKey;
}

@end
