//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxScrollListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxFluencyMonitor : NSObject
+ (instancetype)sharedInstance;

@property(nonatomic, readonly) BOOL shouldSendAllScrollEvent;

- (void)startWithScrollInfo:(LynxScrollInfo*)info;

- (void)stopWithScrollInfo:(LynxScrollInfo*)info;
@end

NS_ASSUME_NONNULL_END
