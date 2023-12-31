//
//  LKCExceptionContinounslyCrashConfig.h
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCustomExceptionConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKCExceptionContinounslyCrashConfig : LKCustomExceptionConfig

@property (nonatomic, assign) double launchTimeThreshold;
@property (nonatomic, assign) int crashCount;

@end

NS_ASSUME_NONNULL_END
