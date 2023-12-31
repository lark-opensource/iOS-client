//
//  TMAPluginTracker.m
//  Timor
//
//  Created by muhuai on 2018/3/11.
//

#import "TMAPluginTracker.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPNetworking.h>
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "OPAPIDefine.h"
#import <TTMicroApp/TTMicroApp-Swift.h>

#define kEventStringMAXLength 85

NSString *const kMonitorReportPlatformTea = @"Tea";
NSString *const kMonitorReportPlatformTeaSlardar = @"TeaSlardar";
NSString *const kMonitorReportPlatformSlardar = @"Slardar";

@implementation TMAPluginTracker

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 方法实现
/*-----------------------------------------------*/

/// 这个私有API通过delegate的方式有另外的实现，但是如果这里不写一个实现，就会报 feature is not supported in app 的异常，考虑改造
- (void)reportTimelineWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback context:(BDPPluginContext)context {
    OPAPICallback *apiCallback = OP_API_CALLBACK;
    apiCallback.invokeSuccess();
}

/// 这个私有API通过delegate的方式有另外的实现，但是如果这里不写一个实现，就会报 feature is not supported in app 的异常，考虑改造
- (void)postErrorsWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback context:(BDPPluginContext)context {
    OPAPICallback *apiCallback = OP_API_CALLBACK;
    apiCallback.invokeSuccess();
}

@end
