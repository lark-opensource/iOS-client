//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxFoldViewSlotDragLight.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>

@interface BDXLynxFoldViewSlotDragLight ()

@end

@implementation BDXLynxFoldViewSlotDragLight

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-slot-drag-ng")
#else
LYNX_REGISTER_UI("x-foldview-slot-drag-ng")
#endif

- (UIView *)createView {
  return [[UIView alloc] init];
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
  [super insertChild:child atIndex:index];
  if ([child isKindOfClass:BDXLynxTabBarPro.class]) {
    self.tabbarPro = child;
  } 
}

- (BOOL)notifyParent {
  return YES;
}

#pragma mark - LYNX_PROPS

LYNX_PROP_SETTER("enable-drag", setEnableDrag, BOOL) {
  self.forbidMovable = !value;
}

@end
