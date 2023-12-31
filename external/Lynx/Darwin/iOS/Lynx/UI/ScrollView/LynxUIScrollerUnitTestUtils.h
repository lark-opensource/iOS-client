// Copyright 2023 The Lynx Authors. All rights reserved.
#import "LynxUIUnitTestUtils.h"

@class LynxUIScroller;
@class LynxUIContext;
@class LynxEventEmitter;
@class LynxUI;

@interface LynxUIScrollerUnitTestUtils : LynxUIUnitTestUtils
+ (void)mockBounceView:(LynxUIMockContext *)context
                direction:(NSString *)direction
    triggerBounceDistance:(CGFloat)distance
                     size:(CGSize)size;

+ (void)mockChildren:(NSInteger)count
             context:(LynxUIMockContext *)context
             scrollY:(BOOL)enableScrollY
                size:(CGSize)size;
@end
