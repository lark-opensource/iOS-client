//
//  LKCExceptionContinounslyCrash.h
//  LarkMonitor
//
//  Created by sniperj on 2020/1/2.
//

#import "LKCExceptionBase.h"

NS_ASSUME_NONNULL_BEGIN

extern double LCKEXCContinounsCrashLaunchTimeThreshold;
extern int LCKEXCContinounsCrashCount;

@interface LKCExceptionContinounslyCrash : LKCExceptionBase

/// 启动间隔时间长度作为启动崩溃
@property (nonatomic, assign) double launchTimeThreshold;
/// 连续多少次崩溃上报
@property (nonatomic, assign) int crashCount;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
