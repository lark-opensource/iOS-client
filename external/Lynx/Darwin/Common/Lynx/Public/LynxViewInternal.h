// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxError.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * The interface provides internal behavior for LynxView and can
 * be accessed by internal framework classes.
 */
@interface LynxView ()

@property(nonatomic, assign) CGSize intrinsicContentSize;
- (void)dispatchError:(LynxError *)error;

- (void)onLongPress;

@end

NS_ASSUME_NONNULL_END
