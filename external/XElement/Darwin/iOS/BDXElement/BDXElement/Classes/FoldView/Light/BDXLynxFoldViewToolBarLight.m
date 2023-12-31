//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxFoldViewToolBarLight.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>

@implementation BDXLynxFoldViewToolBarLight

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-toolbar-ng")
#else
LYNX_REGISTER_UI("x-foldview-toolbar-ng")
#endif

#pragma mark - LynxUI

- (UIView *)createView {
  return [[UIView alloc] init];
}


- (void)updateFrame:(CGRect)frame
        withPadding:(UIEdgeInsets)padding
             border:(UIEdgeInsets)border
             margin:(UIEdgeInsets)margin
withLayoutAnimation:(BOOL)with {
  [super updateFrame:frame withPadding:padding border:border margin:margin withLayoutAnimation:with];
  self.toolbarHeightChanged = YES;
}

- (BOOL)notifyParent {
  return YES;
}

@end
