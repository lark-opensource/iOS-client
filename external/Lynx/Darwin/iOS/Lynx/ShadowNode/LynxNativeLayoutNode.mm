// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxNativeLayoutNode.h"
#import "LynxCustomMeasureDelegate+Internal.h"
#import "LynxLayoutNode+Internal.h"
#import "LynxPropsProcessor.h"

#include "starlight/layout/layout_object.h"
#include "tasm/react/layout_node.h"

using lynx::starlight::Constraints;
using lynx::starlight::kHorizontal;
using lynx::starlight::kVertical;
using lynx::tasm::LayoutNode;
@implementation LynxNativeLayoutNode

- (MeasureResult)measureWithMeasureParam:(MeasureParam *)param
                          MeasureContext:(MeasureContext *)ctx {
  int64_t native_node_ptr = [super getNativeLayoutNodePtr];
  LayoutNode *layout_node = reinterpret_cast<LayoutNode *>(native_node_ptr);

  Constraints constraints;
  constraints[kHorizontal] =
      lynx::starlight::OneSideConstraint(param.width, (SLMeasureMode)param.widthMode);
  constraints[kVertical] =
      lynx::starlight::OneSideConstraint(param.height, (SLMeasureMode)param.heightMode);

  MeasureResult result;
  CGSize resultSize = CGSizeZero;
  if (layout_node != nullptr) {
    FloatSize size = layout_node->UpdateMeasureByPlatform(constraints, ctx.finalMeasure);
    resultSize = CGSizeMake(size.width_, size.height_);
    result.baseline = size.baseline_;
  }

  result.size = resultSize;
  return result;
}
- (void)alignWithAlignParam:(AlignParam *)param AlignContext:(AlignContext *)context {
  int64_t native_node_ptr = [super getNativeLayoutNodePtr];
  LayoutNode *layout_node = reinterpret_cast<LayoutNode *>(native_node_ptr);
  if (layout_node != nullptr) {
    layout_node->AlignmentByPlatform(param.topOffset, param.leftOffset);
  }
}

- (BOOL)supportInlineView {
  return YES;
}

LYNX_PROP_SETTER("vertical-align", setVerticalAlign, NSArray *) {
  [self setVerticalAlignOnShadowNode:requestReset value:value];
}

@end
