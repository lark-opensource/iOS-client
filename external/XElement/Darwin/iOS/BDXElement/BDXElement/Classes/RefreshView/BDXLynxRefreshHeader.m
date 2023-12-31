//
//  BDXLynxRefreshHeader.m
//  BDXElement
//
//  Created by AKing on 2020/10/12.
//

#import "BDXLynxRefreshHeader.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXLynxRefreshHeader

- (UIView *)createView {
    UIView *view = [UIView new];
    return view;
}

- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
    //The actual frame of the header view is (0,-h,w,h), and the frame in lynxUI is (0,0,w,h), so a conversion is made to the y value here to prevent the click event from being intercepted by mistake
    CGPoint fp = CGPointMake(point.x, point.y + self.view.frame.size.height);
    if([self.view pointInside:fp withEvent:event]) {
        return true;
    }
    return false;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-refresh-header")
#else
LYNX_REGISTER_UI("x-refresh-header")
#endif


@end
