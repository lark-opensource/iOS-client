//
//  BDLynxCustomErrorMonitor.m
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/23.
//

#import "BDLynxCustomErrorMonitor.h"
#import "IESLynxPerformanceDictionary.h"
#import "IESLiveMonitorUtils.h"
#import "IESLynxMonitor.h"
#import <Lynx/LynxError.h>
#import "BDHybridMonitorDefines.h"

typedef NS_ENUM(NSInteger, IESLynxMonitorStatus) {
    IESLynxMonitorStatusSucceed,
    IESLynxMonitorStatusFailed,
};

@implementation BDLynxCustomErrorMonitor
+ (BOOL)startMonitorWithSetting:(NSDictionary *)setting {
    BOOL turnOnMonitor = [setting[kBDWMLynxCustomErrorMonitor] boolValue];
    [self setCustomErrorEnable:turnOnMonitor];
    if (!turnOnMonitor) {
        return NO;
    }
    return YES;
}

static BOOL kCustomErrorEnable = YES;
+ (BOOL)customErrorEnable
{
    return kCustomErrorEnable;
}

+ (void)setCustomErrorEnable:(BOOL)customErrorEnable
{
    kCustomErrorEnable = customErrorEnable;
}



+ (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error
{
    if(![self customErrorEnable]) {
        return;
    }
    [view.performanceDic feCustomReportRequestError:error];
    
    NSInteger errCode = error.code;
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    if (errCode == LynxErrorCodeLoadTemplate || errCode == LynxErrorCodeTemplateProvider) {
        [[IESLynxMonitor sharedMonitor] trackLynxService:@"lynx_page_load_all" status:IESLynxMonitorStatusFailed duration:0 extra:@{
            @"err_log": error.userInfo ? : @{}
        }];
        [[IESLynxMonitor sharedMonitor] trackLynxService:@"lynx_page_load_error" status:IESLynxMonitorStatusFailed duration:0 extra:@{
            @"err_log": error.userInfo ? : @{}
        }];

        [view.performanceDic coverWithDic:@{kLynxMonitorLoadFailed : @(ts)}];
        [view.performanceDic reportPerformance];
    } else {
        [[IESLynxMonitor sharedMonitor] trackLynxService:@"lynx_error" status:IESLynxMonitorStatusFailed duration:0 extra:@{
            @"err_log": error.userInfo ? : @{}
        }];
    }
}

@end
