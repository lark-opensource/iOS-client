//
//  HMDCrashStackAnalysis.h
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashAddressAnalysis.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashStackAnalysis : HMDCrashAddressAnalysis

@property (nonatomic,assign) uintptr_t stack_address;

@end

NS_ASSUME_NONNULL_END
