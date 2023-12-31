// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxConverter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxBoxShadow : NSObject

@property(nonatomic, strong) UIColor *shadowColor;
@property(nonatomic, assign) CGFloat offsetX;
@property(nonatomic, assign) CGFloat offsetY;
@property(nonatomic, assign) CGFloat blurRadius;
@property(nonatomic, assign) CGFloat spreadRadius;
@property(nonatomic, assign) BOOL inset;
@property(nonatomic, strong) CALayer *layer;

- (BOOL)isEqualToBoxShadow:(LynxBoxShadow *)other;

@end

@class LynxUI;
@interface LynxConverter (LynxBoxShadow)
+ (NSArray<LynxBoxShadow *> *)toLynxBoxShadow:(id)value;
@end

NS_ASSUME_NONNULL_END
