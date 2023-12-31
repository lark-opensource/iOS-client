//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxShadowNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxCustomMeasureShadowNode : LynxShadowNode

// Call this method to measure child node
- (MeasureResult)measureNativeLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context;

// Call this method to align child node
- (void)alignNativeLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context;

// Subclass should overwrite this implement
- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context;

// Subclass should overwrite this implement
- (void)customAlignLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context;

- (CGFloat)toPtWithUnitValue:(NSString *)unitValue fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
