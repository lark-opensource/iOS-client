//
//  HMDInjectedInfo+PerfOptSwitch.h
//  Aweme
//
//  Created by ByteDance on 2023/8/23.
//

#import "HMDInjectedInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInjectedInfo (PerfOptSwitch)

@property (nonatomic, assign) BOOL ttmonitorCodingProtocolOptEnabled;

@property (nonatomic, assign) BOOL ttMonitorSampleOptEnable;

@end

NS_ASSUME_NONNULL_END
