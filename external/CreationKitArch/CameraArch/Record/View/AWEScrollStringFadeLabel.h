// Copyright © 2021 Bytedance. All rights reserved.

#import "AWEScrollStringLabel.h"


@interface AWEScrollStringFadeLabel : AWEScrollStringLabel

- (instancetype)initWithHeight:(CGFloat)height fadeLayerWidth:(CGFloat)width;

- (void)updateFadeLayerColorWithCurrent:(BOOL)isCurrent;

@end


