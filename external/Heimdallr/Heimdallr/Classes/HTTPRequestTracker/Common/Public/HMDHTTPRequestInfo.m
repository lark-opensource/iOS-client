//
//  HMDHTTPRequestInfo.m
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/3.
//

#import "HMDHTTPRequestInfo.h"
#import "HMDUITrackerTool.h"

@interface HMDHTTPRequestInfo()

// sample declare in Private category
@property (nonatomic, assign) BOOL isURLInBlockList;
@property (nonatomic, assign) BOOL isURLInAllowedList;
@property (nonatomic, assign) BOOL isSDKURLInAllowedList;
@property (nonatomic, assign) BOOL isHeaderInAllowedList;
@property (nonatomic, assign) BOOL isHitMovingLine;
@property (nonatomic, assign) BOOL isMovingLine;

@end

@implementation HMDHTTPRequestInfo

- (instancetype)init {
    if (self = [super init]) {
        _requestID = [[self class] nextRequestID];
        _startTime = [[NSDate date] timeIntervalSince1970];
        id<HMDUITrackerManagerSceneProtocol> sharedManager = hmd_get_uitracker_manager();
        _requestScene = [sharedManager scene];
    }
    
    return self;
}

+ (NSString *)nextRequestID {
    return [[NSUUID UUID] UUIDString];
}

@end
