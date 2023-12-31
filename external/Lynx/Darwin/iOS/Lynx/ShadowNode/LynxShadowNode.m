// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxShadowNode.h"
#import "LynxConverter+LynxCSSType.h"
#import "LynxDefines.h"
#import "LynxPropsProcessor.h"

@implementation LynxShadowNodeStyle
@end

@implementation LynxShadowNode {
  BOOL _needsDisplay;
  __weak id<LynxShadowNodeDelegate> _delegate;
}

LYNX_NOT_IMPLEMENTED(-(instancetype)init)

LYNX_PROPS_GROUP_DECLARE(LYNX_PROP_DECLARE("event-through", setEventThrough, BOOL))

- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString *)tagName {
  self = [super init];
  if (self) {
    _sign = sign;
    _tagName = tagName;
    _isDestroy = NO;
    _eventSet = nil;
    _ignoreFocus = false;
    _enableTouchPseudoPropagation = YES;
    _eventThrough = kLynxEventPropUndefined;
  }
  return self;
}

- (void)setUIOperation:(LynxUIOwner *)owner {
  _uiOwner = owner;
}

- (void)setDelegate:(id<LynxShadowNodeDelegate>)delegate {
  _delegate = delegate;
};

- (void)postExtraDataToUI:(id)value {
  // this method can be removed
}

- (void)postFrameToUI:(CGRect)frame {
  // this method can be removed
}

- (void)setNeedsLayout {
  if (_isDestroy) {
    return;
  }
  if (![self isVirtual]) {
    [super setNeedsLayout];
  } else {
    [[self findNonVirtualNode] setNeedsLayout];
  }
}

- (LynxShadowNode *)findNonVirtualNode {
  if ([self isVirtual]) {
    return [self.parent findNonVirtualNode];
  }
  return self;
}

- (BOOL)isVirtual {
  return NO;
}

LYNX_PROP_SETTER("ignore-focus", setIgnoreFocus, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _ignoreFocus = value;
}

LYNX_PROP_SETTER("enable-touch-pseudo-propagation", setEnableTouchPseudoPropagation, BOOL) {
  if (requestReset) {
    value = YES;
  }
  _enableTouchPseudoPropagation = value;
}

LYNX_PROP_DEFINE("event-through", setEventThrough, BOOL) {
  // If requestReset, the _eventThrough will be Undefined.
  enum LynxEventPropStatus res = kLynxEventPropUndefined;
  if (requestReset) {
    _eventThrough = res;
    return;
  }
  _eventThrough = value ? kLynxEventPropEnable : kLynxEventPropDisable;
}

LYNX_PROP_SETTER("vertical-align", setVerticalAlign, NSArray *) {
  // be compatible with old pages
  if (!_uiOwner.uiContext.enableTextRefactor) {
    [self setVerticalAlignOnShadowNode:requestReset value:value];
  }
}

- (void)setVerticalAlignOnShadowNode:(BOOL)requestReset value:(NSArray *)value {
  if (requestReset) {
    value = nil;
  }

  if (_shadowNodeStyle == nil) {
    _shadowNodeStyle = [LynxShadowNodeStyle new];
  }
  if (value == nil || [value count] < 2) {
    _shadowNodeStyle.valign = LynxVerticalAlignDefault;
  } else {
    _shadowNodeStyle.valign = [LynxConverter toLynxVerticalAlign:[value objectAtIndex:0]];
    _shadowNodeStyle.valignLength = [LynxConverter toCGFloat:[value objectAtIndex:1]];
  }
  [self setNeedsLayout];
}

- (void)destroy {
  _isDestroy = YES;
}

- (id)getExtraBundle {
  return nil;
}

- (BOOL)needsEventSet {
  return NO;
}

- (BOOL)supportInlineView {
  return NO;
}

@end
