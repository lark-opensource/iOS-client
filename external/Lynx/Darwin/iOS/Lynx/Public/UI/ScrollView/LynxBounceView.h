//
//  LynxBounceView.h
//  Copyright 2021 The Lynx Authors. All rights reserved.
//

#import "LynxUIView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LynxBounceViewDirection) {
  LynxBounceViewDirectionRight = 0,
  LynxBounceViewDirectionBottom,
  LynxBounceViewDirectionLeft,
  LynxBounceViewDirectionTop,
};

@interface LynxBounceView : LynxUIView

@property(nonatomic, assign) LynxBounceViewDirection direction;
@property(nonatomic, assign) float space;
@property(nonatomic) CGFloat triggerBounceEventDistance;

@end

NS_ASSUME_NONNULL_END
