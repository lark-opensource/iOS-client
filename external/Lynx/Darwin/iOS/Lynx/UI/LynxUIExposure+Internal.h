// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxUIExposure.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIExposure ()

- (instancetype)initWithObserver:(LynxGlobalObserver *)observer;
- (BOOL)isLynxViewChanged;
- (void)setObserverFrameRate:(int32_t)rate;
- (void)setEnableCheckExposureOptimize:(BOOL)enableCheckExposureOptimize;

@end

NS_ASSUME_NONNULL_END
