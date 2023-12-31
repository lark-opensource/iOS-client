//
//  HMDMonitor+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/22.
//

#import "HMDMonitor.h"

NS_ASSUME_NONNULL_BEGIN

#define SHAREDMONITOR(x) + (instancetype)sharedMonitor\
{\
    static x *sharedMonitor = nil;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        sharedMonitor = [[x alloc] init];\
    });\
    return sharedMonitor;\
}\

@interface HMDMonitor (Private)

@property (nonatomic, strong, readonly) NSDictionary *customUploadDic;
@property (nonatomic, copy) NSString *customSceneStr;

- (void)monitorRunWithSpecialScene;
- (void)monitorStopWithSpecialScene;

@end

NS_ASSUME_NONNULL_END
