// Copyright 2021 The Lynx Authors. All rights reserved.

#import "BDXLynxUINestedScroller.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxUIScroller.h>
#import "LynxNestedScrollView.h"

#pragma mark - BDXLynxNestedScrollView
@implementation BDXLynxNestedScrollView

#pragma mark - LynxPropsProcessor

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-nested-scroll-view")
#else
LYNX_REGISTER_UI("x-nested-scroll-view")
#endif

@end  // BDXLynxNestedScrollView
