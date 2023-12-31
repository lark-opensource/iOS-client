// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxTextOverflowLayer.h"
#import "LynxTextRenderer.h"
#import "LynxTextView.h"
#import "LynxUI+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIText : LynxUI <LynxTextView *>

@property(nonatomic, readonly, nullable) LynxTextRenderer *renderer;
@property(nonatomic, readonly) CGPoint overflowLayerOffset;

- (CALayer *)getOverflowLayer;

@end

NS_ASSUME_NONNULL_END
