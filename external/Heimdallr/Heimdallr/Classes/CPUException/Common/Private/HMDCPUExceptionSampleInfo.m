//
//  HMDCPUExceptionSampleInfo.m
//  Heimdallr-8bda3036
//
//  Created by bytedance on 2022/6/23.
//

#import "HMDCPUExceptionSampleInfo.h"
#import "HMDUITrackerManagerSceneProtocol.h"
#import "HMDDynamicCall.h"

@implementation HMDCPUExceptionSampleInfo

+ (HMDCPUExceptionSampleInfo *)sampleInfo {
    HMDCPUExceptionSampleInfo *currentInfo = [[HMDCPUExceptionSampleInfo alloc] init];
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    // 记录低电量模式
    if (@available(iOS 9.0, *)) {
        currentInfo.isLowPowerModel = [processInfo isLowPowerModeEnabled];
    } else {
        currentInfo.isLowPowerModel = NO;
    }
    // 记录发热状态
    if (@available(iOS 11.0, *)) {
        currentInfo.thermalModel = [processInfo thermalState];
    } else {
        currentInfo.thermalModel = -1; // -1 为未知, 系统版本不支持
    }

    currentInfo.scene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);

    return currentInfo;
}

@end
