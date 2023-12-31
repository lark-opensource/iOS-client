//
//  HMDThreadQosOptimizer.h
//  Pods
//
//  Created by xushuangqing on 2022/1/27.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadQosOptimizer : NSObject

+ (void)toggleNextLaunchQosMockerEnabled:(BOOL)qosMockerEnabled keyQueueCollectorEnabled:(BOOL)keyQueueCollectorEnabled whiteList:(NSArray<NSString *> *)whiteList;
+ (void)markLaunchFinished;
+ (BOOL)keyQueueCollectorEnabled;
+ (BOOL)threadQoSMockerEnabled;

@end

NS_ASSUME_NONNULL_END
