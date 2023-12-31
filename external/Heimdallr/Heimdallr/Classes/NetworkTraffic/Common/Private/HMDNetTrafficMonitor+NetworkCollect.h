//
//  HMDNetTrafficMonitor+NetworkCollect.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/25.
//

#import "HMDNetTrafficMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetTrafficMonitor (NetworkCollect)

- (void)switchNetworkCollectStatus:(BOOL)isOn;
- (void)switchTTPushCollectStatus:(BOOL)isOn;

@end

NS_ASSUME_NONNULL_END
