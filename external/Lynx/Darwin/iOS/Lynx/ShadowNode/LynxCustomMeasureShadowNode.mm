//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxCustomMeasureShadowNode.h"
#import "LynxCustomMeasureDelegate+Internal.h"
#import "LynxCustomMeasureDelegate.h"
#import "LynxLayoutNode+Internal.h"
#import "LynxNativeLayoutNode.h"
#import "LynxPropsProcessor.h"
#import "LynxUnitUtils.h"
#include "starlight/layout/layout_object.h"
#include "tasm/react/layout_node.h"

using lynx::starlight::Constraints;
using lynx::starlight::kHorizontal;
using lynx::starlight::kVertical;
using lynx::tasm::LayoutNode;

@interface LynxCustomMeasureShadowNode () <LynxCustomMeasureDelegate>

@property(nonatomic, assign) BOOL hasCustomLayout;

@end

@implementation LynxCustomMeasureShadowNode

LYNX_PROP_SETTER("custom-layout", customLayout, BOOL) { _hasCustomLayout = value; }

- (BOOL)supportInlineView {
  return YES;
}

- (void)adoptNativeLayoutNode:(int64_t)ptr {
  if (_hasCustomLayout) {
    [self setCustomMeasureDelegate:self];
  }
  [super adoptNativeLayoutNode:ptr];
}

- (MeasureResult)measureNativeLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)ctx {
  MeasureResult result;
  int64_t native_node_ptr = [super getNativeLayoutNodePtr];
  LayoutNode *layout_node = reinterpret_cast<LayoutNode *>(native_node_ptr);
  CGSize resultSize = CGSizeZero;

  Constraints constraints;
  constraints[kHorizontal] =
      lynx::starlight::OneSideConstraint(param.width, (SLMeasureMode)param.widthMode);
  constraints[kVertical] =
      lynx::starlight::OneSideConstraint(param.height, (SLMeasureMode)param.heightMode);

  if (layout_node != nullptr) {
    FloatSize size = layout_node->UpdateMeasureByPlatform(constraints, ctx.finalMeasure);
    resultSize = CGSizeMake(size.width_, size.height_);
  }
  result.size = resultSize;
  return result;
}

- (void)alignNativeLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context {
  int64_t native_node_ptr = [super getNativeLayoutNodePtr];
  LayoutNode *layout_node = reinterpret_cast<LayoutNode *>(native_node_ptr);
  if (layout_node != nullptr) {
    layout_node->AlignmentByPlatform(param.topOffset, param.leftOffset);
  }
}

- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)ctx {
  return (MeasureResult){CGSizeZero, 0.f};
}

- (void)customAlignLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context {
}

#pragma mark - LynxCustomMeasureDelegate

- (void)alignWithAlignParam:(nonnull AlignParam *)param
               AlignContext:(nonnull AlignContext *)context {
  [self customAlignLayoutNode:param alignContext:context];
}

- (MeasureResult)measureWithMeasureParam:(nonnull MeasureParam *)param
                          MeasureContext:(nullable MeasureContext *)context {
  MeasureResult result = [self customMeasureLayoutNode:param measureContext:context];
  return result;
}

- (CGFloat)toPtWithUnitValue:(NSString *)unitValue fontSize:(CGFloat)fontSize {
  LynxUI *rootUI = (LynxUI *)self.uiOwner.uiContext.rootUI;
  return [LynxUnitUtils toPtWithScreenMetrics:self.uiOwner.uiContext.screenMetrics
                                    unitValue:unitValue
                                 rootFontSize:rootUI.fontSize
                                  curFontSize:fontSize
                                    rootWidth:CGRectGetWidth(rootUI.frame)
                                   rootHeight:CGRectGetHeight(rootUI.frame)
                                withDefaultPt:0];
}

@end
