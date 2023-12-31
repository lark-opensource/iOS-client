// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxInlineTextShadowNode.h"
#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"

@implementation LynxInlineTextShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("inline-text")
#else
LYNX_REGISTER_SHADOW_NODE("inline-text")
#endif

- (BOOL)isVirtual {
  return YES;
}

- (BOOL)needsEventSet {
  return YES;
}

LYNX_PROP_SETTER("vertical-align", setVerticalAlign, NSArray *) {
  [self setVerticalAlignOnShadowNode:requestReset value:value];
}

@end
