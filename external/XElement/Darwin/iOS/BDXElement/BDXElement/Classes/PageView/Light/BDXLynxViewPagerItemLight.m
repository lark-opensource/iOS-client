//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxViewPagerItemLight.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>


@interface BDXLynxViewPagerItemLight ()

@end

@implementation BDXLynxViewPagerItemLight

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-viewpager-item-ng")
#else
LYNX_REGISTER_UI("x-viewpager-item-ng")
#endif

- (UIView *)createView {
  return [[UIView alloc] init];
}

@end
