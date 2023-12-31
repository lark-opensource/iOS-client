//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxGlobalObserver.h"

@interface LynxGlobalObserver ()

typedef void (^callback)(NSDictionary* options);

- (void)setObserverFrameRate:(int32_t)rate;

- (void)addAnimationObserver:(callback)callback;
- (void)removeAnimationObserver:(callback)callback;

- (void)addLayoutObserver:(callback)callback;
- (void)removeLayoutObserver:(callback)callback;

- (void)addScrollObserver:(callback)callback;
- (void)removeScrollObserver:(callback)callback;

- (void)addPropertyObserver:(callback)callback;
- (void)removePropertyObserver:(callback)callback;

@end
