//
//  IESGurdResourceManager+Status.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import "IESGeckoResourceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdResourceManager (Status)

@property (class, nonatomic, assign, getter=isRetryEnabled) BOOL retryEnabled;

@property (class, nonatomic, assign, getter=isPollingEnabled) BOOL pollingEnabled;

+ (void)updateServerAvailable:(BOOL)isAvailable;

+ (BOOL)checkIfServerAvailable;

@end

NS_ASSUME_NONNULL_END
