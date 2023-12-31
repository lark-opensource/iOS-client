//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxLayoutTick.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxView;

@interface LynxUILayoutTick : LynxLayoutTick

- (instancetype)initWithRoot:(LynxView*)root block:(nonnull LynxOnLayoutBlock)block;

/**
 * attach view for request layout
 * @param root root view
 */
- (void)attach:(LynxView* _Nonnull)root;

@end

NS_ASSUME_NONNULL_END
