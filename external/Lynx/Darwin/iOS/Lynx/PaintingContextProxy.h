//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxShadowNode.h"
#include "tasm/react/ios/painting_context_darwin.h"

NS_ASSUME_NONNULL_BEGIN

@interface PaintingContextProxy : NSObject <LynxShadowNodeDelegate>

- (instancetype)initWithPaintingContext:(lynx::tasm::PaintingContextDarwin*)paintingContext;

/**
 * set enable flush
 */
- (void)setEnableFlush:(BOOL)enableFlush;

/**
 * Flush UI operation queue to trigger painting process
 */
- (void)forceFlush;

/**
 * Get layout status
 */
- (BOOL)isLayoutFinish;

/**
 * Update the status of the layout to unfinished
 */
- (void)resetLayoutStatus;

@end

NS_ASSUME_NONNULL_END
