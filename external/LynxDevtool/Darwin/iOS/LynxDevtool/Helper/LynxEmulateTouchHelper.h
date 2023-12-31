// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxView.h>
#import "LynxInspectorOwner.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxEmulateTouchHelper : NSObject

- (nonnull instancetype)initWithLynxView:(LynxView*)view withOwner:(LynxInspectorOwner*)owner;

+ (void)emulateTouch:(NSDictionary*)dict;

- (void)emulateTouch:(nonnull NSString*)type
         coordinateX:(int)x
         coordinateY:(int)y
              button:(nonnull NSString*)button
              deltaX:(CGFloat)dx
              deltaY:(CGFloat)dy
           modifiers:(int)modifiers
          clickCount:(int)click_count;

- (void)attachLynxView:(nonnull LynxView*)lynxView;
@end

NS_ASSUME_NONNULL_END
