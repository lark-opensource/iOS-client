//
//  HMDCPUExceptionMonitor+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/5/19.
//

#import "HMDCPUExceptionMonitor.h"
#import "HMDExceptionReporter.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionMonitor (Private)

- (void)fetchCloudCommandCPUExceptionOneCycleInfoWithCompletion:(void (^)(NSDictionary * _Nullable, BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
