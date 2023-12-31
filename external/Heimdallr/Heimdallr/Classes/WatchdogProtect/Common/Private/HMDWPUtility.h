//
//  HMDWPUtility.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/13.
//

#import <Foundation/Foundation.h>
#import "HMDWatchdogProtectDefine.h"
#import <stdatomic.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDWatchdogProtectErrorCode) {
    HMDWatchdogProtectErrorCodeSuccess = 0,
    HMDWatchdogProtectErrorCodeDynamicMethodEmpty,
    HMDWatchdogProtectErrorCodeDynamicMethodInvalidPrefix,
    HMDWatchdogProtectErrorCodeDynamicMethodInvalidFormat,
    HMDWatchdogProtectErrorCodeDynamicMethodInvalidClassOrSelectorName,
    HMDWatchdogProtectErrorCodeDynamicMethodInvalidClass,
    HMDWatchdogProtectErrorCodeDynamicMethodBlockedSelector,
};

FOUNDATION_EXPORT NSErrorDomain const HMDWatchdogProtectErrorDomain;

@interface HMDWPUtility : NSObject

+ (void)protectClass:(Class)cls
          slector:(SEL)selector
        skippedDepth:(NSUInteger)skippedDepth
            waitFlag:(atomic_flag * _Nullable)waitFlag
     syncWaitTime:(NSTimeInterval)syncWaitTime
 exceptionTimeout:(NSTimeInterval)exceptionTimeout
exceptionCallback:(HMDWPExceptionCallback)exceptionCallback
     protectBlock:(dispatch_block_t)block;

+ (void)protectObject:(id)object
              slector:(SEL)selector
         skippedDepth:(NSUInteger)skippedDepth
             waitFlag:(atomic_flag * _Nullable)waitFlag
         syncWaitTime:(NSTimeInterval)syncWaitTime
     exceptionTimeout:(NSTimeInterval)exceptionTimeout
    exceptionCallback:(HMDWPExceptionCallback)exceptionCallback
         protectBlock:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
