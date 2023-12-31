// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxAnimationInfo.h"

NS_ASSUME_NONNULL_BEGIN
@class LynxUI;

@interface LynxLayoutAnimationManager : NSObject

@property(nonatomic, strong, nullable) LynxAnimationInfo* createConfig;
@property(nonatomic, strong, nullable) LynxAnimationInfo* updateConfig;
@property(nonatomic, strong, nullable) LynxAnimationInfo* deleteConfig;

- (instancetype)initWithLynxUI:(LynxUI*)ui;

- (void)removeAllLayoutAnimation;

- (BOOL)maybeUpdateFrameWithLayoutAnimation:(CGRect)newFrame
                                withPadding:(UIEdgeInsets)padding
                                     border:(UIEdgeInsets)border
                                     margin:(UIEdgeInsets)margin;

@end

NS_ASSUME_NONNULL_END
