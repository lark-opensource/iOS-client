//
//  HMDMonitorDataManager+Upload.m
//  Heimdallr
//
//  Created by 王佳乐 on 2019/1/22.
//

#import "HMDMonitorDataManager+Upload.h"
#import "HMDTTMonitorUserInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+CustomInfo.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDTTMonitorUserInfo.h"
#import "HMDInfo.h"
#import "HMDInjectedInfo.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDTTMonitorHelper.h"
#import "HMDTTMonitorUserInfo+Private.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDMonitorDataManager (Upload)

- (NSDictionary *)reportHeaderParams {
    return [HMDTTMonitorHelper reportHeaderParamsWithInjectedInfo:self.injectedInfo];
}

- (NSDictionary *)reportCommonParams {
    return [self.injectedInfo currentCommonParams];
}

- (BOOL)enableBackgroundUpload {
    return self.injectedInfo.enableBackgroundUpload;
}

@end
