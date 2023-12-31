//
//  BDXExpandLynxInput.m
//  BDXElement
//
//  Created by li keliang on 2020/8/9.
//

#import "BDXExpandLynxInput.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXExpandLynxInput

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-input")
#else
LYNX_REGISTER_UI("x-input")
#endif

@end
