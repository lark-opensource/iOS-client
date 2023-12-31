//
//  HMDTTMonitorInterceptorParams.m
//  Heimdallr
//
//  Created by liuhan on 2023/9/18.
//

#import "HMDTTMonitorInterceptorParam.h"
#import "HMDTTMonitorTrackerInterface.h"

@implementation HMDTTMonitorInterceptorParam

- (instancetype)init
{
    self = [super init];
    if (self) {
        _storeType = HMDTTmonitorStoreActionNormal;
        _accumulateCount = 0;
        _needUpload = NO;
        _traceParent = @"";
        _singlePointOnly = 0;
    }
    return self;
}

@end
