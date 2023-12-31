//
//  BDXExpandLynxOverlayView.m
//  BDXElement
//
//  Created by li keliang on 2020/8/9.
//

#import "BDXExpandLynxOverlayView.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXExpandLynxOverlayView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-overlay")
#else
LYNX_REGISTER_UI("x-overlay")
#endif

@end
