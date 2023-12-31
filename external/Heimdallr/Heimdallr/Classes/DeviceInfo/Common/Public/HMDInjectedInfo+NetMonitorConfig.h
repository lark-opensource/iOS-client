//
//  HMDInjectedInfo+NetMonitorConfig.h
//  Heimdallr
//
//  Created by ByteDance on 2023/6/30.
//

#import "HMDInjectedInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInjectedInfo (NetMonitorConfig)

@property (nonatomic, assign) BOOL allowedURLRegularOptEnabled;
@property (nonatomic, assign) BOOL notProductHTTPRecordUnHitEnabled;

@end

NS_ASSUME_NONNULL_END
