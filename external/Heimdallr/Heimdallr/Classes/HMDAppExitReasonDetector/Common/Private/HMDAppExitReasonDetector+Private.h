//
//  HMDAppExitReasonDetector+Private.h
//  Heimdallr
//
//  Created by wangyinhui on 2023/1/11.
//

#import "HMDAppExitReasonDetector.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDAppExitReasonDetector (Private)

@property(class, assign) BOOL isFixNoDataMisjudgment;

@property(class, assign) BOOL isNeedBinaryInfo;

+(void)start;

+(void)stop;

@end

NS_ASSUME_NONNULL_END
