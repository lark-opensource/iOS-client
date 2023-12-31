// Copyright 2021 The Lynx Authors. All rights reserved.

#import "UIScrollView+BDXPageView.h"
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import "NSObject+BDXPageKVO.h"

@implementation UIScrollView (BDXPageView)

AWELazyRegisterPremainClassCategory(UIScrollView,BDXPageView) {
    [self btd_swizzleInstanceMethod:sel_registerName("dealloc") with:@selector(bdxpage_dealloc)];
}

- (void)bdxpage_dealloc {
    [self bdx_removeObserverBlocks];
    [self bdxpage_dealloc];
}

@end
