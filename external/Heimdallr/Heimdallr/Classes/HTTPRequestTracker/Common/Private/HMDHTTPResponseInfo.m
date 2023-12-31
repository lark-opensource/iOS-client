//
//  HMDHTTPResponseInfo.m
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/3.
//

#import "HMDHTTPResponseInfo.h"
#import "HMDSessionTracker.h"
#import "HMDUITrackerTool.h"

@implementation HMDHTTPResponseInfo

- (instancetype)init {
    if (self = [super init]) {
        _endTime = [[NSDate date] timeIntervalSince1970];
        _isForeground = ![HMDSessionTracker currentSession].isBackgroundStatus;
        _inAppTime = [HMDSessionTracker currentSession].timeInSession;
        id<HMDUITrackerManagerSceneProtocol> sharedManager = hmd_get_uitracker_manager();
        _responseScene = [sharedManager scene];
    }
    return self;
}

@end
