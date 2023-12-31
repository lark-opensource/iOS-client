// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxBackgroundDrawable.h"
#import "LynxBackgroundUtils.h"
#pragma mark LynxBackgroundImageLayerInfo

NS_ASSUME_NONNULL_BEGIN
@interface LynxBackgroundImageLayerInfo : NSObject
// property item must be type of NSURL, LynxGradient or LynxBackgroundDrawable.
// the maintainability of this piece of code is low and need to be refactored as quickly as
// possible.
@property(atomic, nullable) LynxBackgroundDrawable* item;
@property(nonatomic, assign) CGRect paintingRect, clipRect, contentRect, borderRect, paddingRect;
@property(nonatomic, assign) LynxBackgroundOriginType backgroundOrigin;
@property(nonatomic, assign) LynxBackgroundRepeatType repeatXType;
@property(nonatomic, assign) LynxBackgroundRepeatType repeatYType;
@property(atomic, nullable) LynxBackgroundSize* backgroundSizeX;
@property(atomic, nullable) LynxBackgroundSize* backgroundSizeY;
@property(atomic, nullable) LynxBackgroundPosition* backgroundPosX;
@property(atomic, nullable) LynxBackgroundPosition* backgroundPosY;
@property(nonatomic, assign) LynxBackgroundClipType backgroundClip;
@property(nonatomic, assign) LynxCornerInsets cornerInsets;
- (void)drawInContext:(CGContextRef _Nullable)ctx;
@end

void LynxPathAddRoundedRect(CGMutablePathRef path, CGRect bounds, LynxCornerInsets ci);
NS_ASSUME_NONNULL_END
