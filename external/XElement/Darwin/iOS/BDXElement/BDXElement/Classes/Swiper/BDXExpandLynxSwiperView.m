//
//  BDXExpandLynxSwiperView.m
//  BDXElement
//
//  Created by li keliang on 2020/8/10.
//

#import "BDXExpandLynxSwiperView.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXExpandLynxSwiperView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-swiper")
#else
LYNX_REGISTER_UI("x-swiper")
#endif

@end
