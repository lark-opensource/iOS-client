// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxLayoutNode.h"
#import "LynxCustomMeasureDelegate+Internal.h"
#import "LynxLayoutNode+Internal.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"

#include "starlight/layout/layout_object.h"
#include "tasm/react/layout_node.h"
using namespace lynx::tasm;
using lynx::starlight::Constraints;
using lynx::starlight::kHorizontal;
using lynx::starlight::kVertical;

@implementation MeasureParam

- (id)initWithWidth:(CGFloat)width
          WdithMode:(LynxMeasureMode)widthMode
             Height:(CGFloat)height
         HeightMode:(LynxMeasureMode)heightMode {
  return [self initWithWidth:width WidthMode:widthMode Height:height HeightMode:heightMode];
}

- (id)initWithWidth:(CGFloat)width
          WidthMode:(LynxMeasureMode)widthMode
             Height:(CGFloat)height
         HeightMode:(LynxMeasureMode)heightMode {
  if (self = [super init]) {
    _width = width;
    _widthMode = widthMode;
    _height = height;
    _heightMode = heightMode;
  }
  return self;
}

@end

@implementation MeasureContext

- (id)initWithFinalMeasure:(bool)finalMeasure {
  if (self = [super init]) {
    _finalMeasure = finalMeasure;
  }
  return self;
}

@end

@implementation AlignParam
- (void)SetAlignOffsetWithLeft:(CGFloat)leftOffset Top:(CGFloat)topOffset {
  _leftOffset = leftOffset;
  _topOffset = topOffset;
}
@end

@implementation AlignContext

@end

@implementation LynxLayoutNode {
  int64_t native_node_ptr_;
}

#ifndef LynxGetLayoutNode
#define LynxGetLayoutNode reinterpret_cast<LayoutNode *>(native_node_ptr_)

- (void)turboNativeLayoutNode {
  if (LynxGetLayoutNode != nullptr && LynxGetLayoutNode->slnode() != nullptr &&
      (_measureDelegate || _customMeasureDelegate)) {
    LynxGetLayoutNode->slnode()->SetContext((__bridge void *)self);
    LynxGetLayoutNode->slnode()->SetSLMeasureFunc(LynxMeasureFunc);
    if (_customMeasureDelegate) {
      LynxGetLayoutNode->slnode()->SetSLAlignmentFunc(LynxAlignmentFunc);
    }
  }
}

- (void)adoptNativeLayoutNode:(int64_t)ptr {
  native_node_ptr_ = ptr;
  _style = [[LynxLayoutStyle alloc] initWithNativePtr:ptr];
  [self turboNativeLayoutNode];
}

- (int64_t)getNativeLayoutNodePtr {
  return native_node_ptr_;
}

FloatSize LynxMeasureFunc(void *context, const Constraints &constraints, bool final_measure) {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxLayoutNode.LynxMeasureFunc");
  float width = 0.f, height = 0.f;
  if (!IsSLIndefiniteMode(constraints[kHorizontal].Mode())) {
    width = constraints[kHorizontal].Size();
  }
  if (!IsSLIndefiniteMode(constraints[kVertical].Mode())) {
    height = constraints[kVertical].Size();
  }
  LynxMeasureMode widthMode = (LynxMeasureMode)constraints[kHorizontal].Mode();
  LynxMeasureMode heightMode = (LynxMeasureMode)constraints[kVertical].Mode();

  LynxLayoutNode *node = (__bridge LynxLayoutNode *)context;

  CGSize resultSize = CGSizeZero;
  CGFloat resultBaseline = 0.f;
  if ([node measureDelegate] != nil) {
    resultSize = [[node measureDelegate] measureNode:node
                                           withWidth:width
                                           widthMode:widthMode
                                              height:height
                                          heightMode:heightMode];
  } else if ([node customMeasureDelegate] != nullptr) {
    MeasureContext *measure_context = [[MeasureContext alloc] initWithFinalMeasure:final_measure];
    MeasureParam *param = [[MeasureParam alloc] initWithWidth:width
                                                    WidthMode:widthMode
                                                       Height:height
                                                   HeightMode:heightMode];
    MeasureResult result = [[node customMeasureDelegate] measureWithMeasureParam:param
                                                                  MeasureContext:measure_context];
    // custom measure delegate should return baseline if needed
    resultSize = result.size;
    resultBaseline = result.baseline;
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return (FloatSize){static_cast<float>(resultSize.width), static_cast<float>(resultSize.height),
                     static_cast<float>(resultBaseline)};
}

void LynxAlignmentFunc(void *context) {
  LynxLayoutNode *node = (__bridge LynxLayoutNode *)context;
  if ([node customMeasureDelegate] != nullptr) {
    AlignParam *param = [[AlignParam alloc] init];
    AlignContext *context = [[AlignContext alloc] init];
    [[node customMeasureDelegate] alignWithAlignParam:param AlignContext:context];
  }
}

- (void)setMeasureDelegate:(id<LynxMeasureDelegate>)measureDelegate {
  _measureDelegate = measureDelegate;
  [self turboNativeLayoutNode];
}

- (void)setCustomMeasureDelegate:(id<LynxCustomMeasureDelegate>)measureDelegate {
  _customMeasureDelegate = measureDelegate;
  [self turboNativeLayoutNode];
}

- (void)updateLayoutWithFrame:(CGRect)frame {
  _frame = frame;
  [self layoutDidUpdate];
}

- (void)setNeedsLayout {
  if (LynxGetLayoutNode == nullptr || LynxGetLayoutNode->slnode() == nullptr) {
    return;
  }
  LynxGetLayoutNode->slnode()->MarkDirtyAndRequestLayout();
}

- (BOOL)needsLayout {
  if (LynxGetLayoutNode == nullptr || LynxGetLayoutNode->slnode() == nullptr) {
    return NO;
  }
  return LynxGetLayoutNode->slnode()->IsDirty();
}

- (void)layoutDidStart {
}
- (void)layoutDidUpdate {
}

- (BOOL)hasCustomLayout {
  return NO;
}
@end

#endif
