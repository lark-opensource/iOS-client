//
//  HMDHeimdallrConfig+CloudCommand.h
//  Heimdallr
//
//  Created by liuhan on 2022/12/12.
//

#import "HMDHeimdallrConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHeimdallrConfig (CloudCommand)

//cloudcommand
@property (nonatomic, strong, readonly, nullable) HMDCloudCommandConfig *cloudCommandConfig;

@end

NS_ASSUME_NONNULL_END
