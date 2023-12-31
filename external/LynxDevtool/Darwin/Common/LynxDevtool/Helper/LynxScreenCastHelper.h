// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxInspectorOwner.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxScreenCastHelper : NSObject

- (nonnull instancetype)initWithLynxView:(LynxView*)view withOwner:(LynxInspectorOwner*)owner;

- (void)startCasting:(int)quality width:(int)max_width height:(int)max_height;
- (void)stopCasting;
- (void)continueCasting;
- (void)pauseCasting;
- (void)attachLynxView:(nonnull LynxView*)lynxView;
- (void)onAckReceived;

- (NSString*)takeCardPreview;

@end

NS_ASSUME_NONNULL_END
