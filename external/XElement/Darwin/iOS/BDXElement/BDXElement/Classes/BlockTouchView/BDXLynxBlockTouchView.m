//
//  BDXLynxBlockTouchView.m
//  BDXElement
//
//  Created by li linyiyi on 2020/9/6.
//

#import "BDXLynxBlockTouchView.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXLynxBlockTouchView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-block-touch")
#else
LYNX_REGISTER_UI("x-block-touch")
#endif

@end
