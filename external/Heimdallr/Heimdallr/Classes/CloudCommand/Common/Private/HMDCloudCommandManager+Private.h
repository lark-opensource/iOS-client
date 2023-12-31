//
//  HMDCloudCommandManager+config.h
//  Heimdallr
//
//  Created by liuhan on 2022/12/5.
//

#import "HMDCloudCommandManager.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDCloudCommandConfig;

@interface HMDCloudCommandManager (Private)

@property (nonatomic, strong, readonly) HMDCloudCommandConfig *cloudCommandConfig;

@property (atomic, assign, readonly) BOOL isUpdatedConfig;

- (void)updateConfig:(HMDCloudCommandConfig *)config;

- (void)setDiskComplianceHandler;

@end

NS_ASSUME_NONNULL_END
