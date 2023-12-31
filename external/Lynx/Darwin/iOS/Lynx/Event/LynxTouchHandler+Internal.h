// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxTouchHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxTouchHandler ()

@property(nonatomic) NSMutableArray<LynxWeakProxy*>* touchDeque;
@property(nonatomic) int32_t tapSlop;

- (void)setEnableTouchRefactor:(BOOL)enable;
- (void)setEnableEndGestureAtLastFingerUp:(BOOL)enable;
- (void)setEnableTouchPseudo:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
