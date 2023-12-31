//
//  MMMemoryAdapter+Private.h
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import "MMMemoryAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMMemoryAdapter (Private)

- (void)reportError:(int)errorCode;
- (void)reportReason:(NSString *)reasonString;

- (void)setCurrentRecordInvalid;

@end

NS_ASSUME_NONNULL_END
