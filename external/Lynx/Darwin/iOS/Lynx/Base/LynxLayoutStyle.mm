// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxLayoutStyle.h"
#import <Foundation/Foundation.h>

#include "starlight/layout/layout_object.h"
#include "starlight/types/measure_context.h"
#include "starlight/types/nlength.h"
#include "tasm/react/layout_node.h"
using namespace lynx::tasm;
using namespace lynx::starlight;

@implementation LynxLayoutStyle {
  int64_t native_node_ptr_;
}

- (instancetype)initWithNativePtr:(int64_t)ptr {
  self = [super init];
  if (self) {
    native_node_ptr_ = ptr;
  }
  return self;
}

const ComputedCSSStyle* LynxGetCSSStyle(int64_t native_node_ptr) {
  return reinterpret_cast<LayoutNode*>(native_node_ptr)->slnode()->GetCSSStyle();
}

- (LynxFlexDirection)flexDirection {
  return (LynxFlexDirection)LynxGetCSSStyle(native_node_ptr_)->GetFlexDirection();
}

- (CGFloat)computedMarginLeft {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetMarginLeft())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedMarginRight {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetMarginRight())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedMarginTop {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetMarginTop())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedMarginBottom {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetMarginBottom())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedPaddingLeft {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetPaddingLeft())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedPaddingRight {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetPaddingRight())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedPaddingTop {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetPaddingTop())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedPaddingBottom {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetPaddingBottom())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedWidth {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetWidth())
      .ClampIndefiniteToZero()
      .ToFloat();
}

- (CGFloat)computedHeight {
  return NLengthToFakeLayoutUnit(LynxGetCSSStyle(native_node_ptr_)->GetHeight())
      .ClampIndefiniteToZero()
      .ToFloat();
}
@end
