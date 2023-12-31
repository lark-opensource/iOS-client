// Copyright 2019 The Lynx Authors. All rights reserved.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@class LynxLayoutNode;

typedef NS_ENUM(NSInteger, LynxMeasureMode) {
  LynxMeasureModeIndefinite = 0,
  LynxMeasureModeDefinite = 1,
  LynxMeasureModeAtMost = 2
};

NS_ASSUME_NONNULL_BEGIN

@protocol LynxMeasureDelegate <NSObject>

- (CGSize)measureNode:(LynxLayoutNode*)node
            withWidth:(CGFloat)width
            widthMode:(LynxMeasureMode)widthMode
               height:(CGFloat)height
           heightMode:(LynxMeasureMode)heightMode;
@end

NS_ASSUME_NONNULL_END
