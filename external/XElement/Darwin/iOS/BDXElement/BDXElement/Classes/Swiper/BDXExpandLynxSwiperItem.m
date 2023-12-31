//
//  BDXExpandLynxSwiperItem.m
//  BDXElement
//
//  Created by li keliang on 2020/8/10.
//

#import "BDXExpandLynxSwiperItem.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXExpandLynxSwiperItem

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-swiper-item")
#else
LYNX_REGISTER_UI("x-swiper-item")
#endif

@end
