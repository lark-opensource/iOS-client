//
//  HMDNetQualityManager.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "HMDNetQualityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDNetQualityDidChange;
extern NSString *const kHMDNetQualityDidChangeUserInfoQualityKey;

@interface HMDNetQualityTracker : NSObject <HMDNetQualityProtocol>

@property (nonatomic, assign, readonly) NSInteger currentNetQuality;

+ (instancetype)sharedTracker;

- (void)switchNetQualityTrackerStatus:(BOOL)isOn;
- (void)startNetQualityMonitor;
- (void)stopNetQualityMonitor;

@end

NS_ASSUME_NONNULL_END
