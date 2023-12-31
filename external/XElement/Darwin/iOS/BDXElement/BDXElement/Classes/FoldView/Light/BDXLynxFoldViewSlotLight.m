//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxFoldViewSlotLight.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>


@interface BDXLynxFoldViewSlotLight ()
@end

@implementation BDXLynxFoldViewSlotLight
#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-slot-ng")
#else
LYNX_REGISTER_UI("x-foldview-slot-ng")
#endif


#pragma mark - LynxUI

- (UIView *)createView {
  return [[UIView alloc] init];
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
  [super insertChild:child atIndex:index];
  if ([child isKindOfClass:BDXLynxTabBarPro.class]) {
    self.tabbarPro = child;
  } else if ([child isKindOfClass:BDXLynxFoldViewSlotDragLight.class]) {
    self.slotDrag = child;
  }
}

- (BOOL)notifyParent {
  return YES;
}

@end
