//
//  LKCExceptionCPU.h
//  LarkMonitor
//
//  Created by sniperj on 2020/1/2.
//

#import "LKCExceptionBase.h"

NS_ASSUME_NONNULL_BEGIN

extern double LKCEXCCPUDefaultLowUsageRate;
extern double LKCEXCCPUDefaultMiddleUsageRate;
extern double LKCEXCCPUDefaultHighUsageRate;

@interface LKCExceptionCPU : LKCExceptionBase

/// CPU异常low level 默认50%
@property (nonatomic, assign) double lowUsageRate;
/// CPU异常middle level 默认80%
@property (nonatomic, assign) double middleUsageRate;
/// CPU异常high level 默认100%
@property (nonatomic, assign) double highUsageRate;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
