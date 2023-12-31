// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUI.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxRootUI : LynxUI <LynxView *>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithView:(nullable UIView *)view NS_UNAVAILABLE;

- (instancetype)initWithLynxView:(LynxView *)lynxView;

- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
                 margin:(UIEdgeInsets)margin
    withLayoutAnimation:(BOOL)with;

- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
    withLayoutAnimation:(BOOL)with;

@property(nonatomic, readonly, weak) LynxView *lynxView;
@property(nonatomic) BOOL layoutAnimationRunning;

@end

NS_ASSUME_NONNULL_END
