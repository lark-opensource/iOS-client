//
//  HMDThreadMonitorInfo.m
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/7.
//

#import "HMDThreadMonitorInfo.h"

@implementation HMDThreadMonitorInfo

- (instancetype)init {
    if(self = [super init]) {
        _allThreadDic = [NSMutableDictionary dictionary];
        _mostThread = @"unknown";
        _mostThreadCount = 0;
        _allThreadCount = 0;
    }
    return self;
}

@end
