//
//  BDXLynxSwiperItem.m
//  BDXElement
//
//  Created by bill on 2020/3/26.
//

#import "BDXLynxSwiperItem.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXLynxSwiperItem

//LYNX_REGISTER_UI("x-swiper-item")
#if LYNX_LAZY_LOAD
+(void)lynxLazyLoad {
  LYNX_BASE_INIT_METHOD
  [LynxComponentRegistry registerUI:self withName:@"x-swiper-item"];
  [LynxComponentRegistry registerUI:self withName:@"swiper-item"];
}
#else
+(void)load {
    [LynxComponentRegistry registerUI:self withName:@"x-swiper-item"];//兼容老版本
    [LynxComponentRegistry registerUI:self withName:@"swiper-item"];
}
#endif

- (UIView*)createView {
    UIView* view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    view.clipsToBounds = YES;
    // Disable AutoLayout
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    return view;
}

@end
