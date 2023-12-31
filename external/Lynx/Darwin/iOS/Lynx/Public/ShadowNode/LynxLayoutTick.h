// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

typedef void (^LynxOnLayoutBlock)(void);

// TODO: use producer and consumer mode
@interface LynxLayoutTick : NSObject

- (nonnull instancetype)initWithBlock:(nonnull LynxOnLayoutBlock)block;

- (void)requestLayout;
- (void)triggerLayout;
- (void)cancelLayoutRequest;

@end
