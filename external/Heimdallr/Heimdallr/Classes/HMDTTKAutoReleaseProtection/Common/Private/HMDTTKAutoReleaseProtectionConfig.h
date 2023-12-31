//
//  HMDTTKAutoReleaseProtectionConfig.h
//  Heimdallr-_Dummy
//
//  Created by zhouyang11 on 2022/7/12.
//

#import "HMDModuleConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDModuleAutoReleaseProtection;

@interface HMDTTKAutoReleaseProtectionConfig : HMDModuleConfig

@property (nonatomic, strong) NSArray<NSString *>* methodGroupArray;

@end

NS_ASSUME_NONNULL_END
