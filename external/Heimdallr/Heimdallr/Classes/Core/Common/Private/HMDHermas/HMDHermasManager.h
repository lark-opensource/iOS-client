//
//  HMDHermasManager.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 22/3/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMDHeimdallrConfig;
@class HMInstance;

@interface HMDHermasManager : NSObject

+ (instancetype)defaultManager;

- (void)updateConfig:(HMDHeimdallrConfig * _Nullable)config;

+ (HMInstance *)sharedPerformanceInstance;

+ (HMInstance *)sharedHighPriorityInstance;

@end

NS_ASSUME_NONNULL_END
