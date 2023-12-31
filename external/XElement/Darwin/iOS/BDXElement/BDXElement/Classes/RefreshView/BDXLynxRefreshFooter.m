//
//  BDXLynxRefreshFooter.m
//  BDXElement
//
//  Created by AKing on 2020/10/19.
//

#import "BDXLynxRefreshFooter.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXLynxRefreshFooter

- (UIView *)createView {
    UIView *view = [UIView new];
    return view;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-refresh-footer")
#else
LYNX_REGISTER_UI("x-refresh-footer")
#endif

@end
