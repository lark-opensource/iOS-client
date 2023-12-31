//
//  LKCExcptionCPUConfig.h
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCustomExceptionConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKCExcptionCPUConfig : LKCustomExceptionConfig

@property (nonatomic, assign) double lowUsageRate;
@property (nonatomic, assign) double middleUsageRate;
@property (nonatomic, assign) double highUsageRate;

@end

NS_ASSUME_NONNULL_END
