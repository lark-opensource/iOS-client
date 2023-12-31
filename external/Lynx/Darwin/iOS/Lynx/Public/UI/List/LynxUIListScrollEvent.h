// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxUIListDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LynxUIListScrollEvent <NSObject>
- (void)addListDelegate:(id<LynxUIListDelegate>)delegate;
- (void)removeListDelegate:(id<LynxUIListDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
