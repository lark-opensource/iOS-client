//
//  BDXExpandLynxUIPicker.m
//  BDXElement
//
//  Created by li keliang on 2020/8/9.
//

#import "BDXExpandLynxUIPicker.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXExpandLynxUIPicker

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-picker")
#else
LYNX_REGISTER_UI("x-picker")
#endif

@end
