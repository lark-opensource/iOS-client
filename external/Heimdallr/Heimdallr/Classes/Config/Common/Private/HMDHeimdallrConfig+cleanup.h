//
//  HMDHeimdallrConfig+cleanup.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/1/23.
//

#import "HMDHeimdallrConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHeimdallrConfig (cleanup)
- (void)prepareCleanConfig:(HMDCleanupConfig *)cleanConfig;
@end

NS_ASSUME_NONNULL_END
