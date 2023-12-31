//
//  BDXRevealViewInnerView.m
//  BDXElement
//
//  Created by bytedance on 2020/10/27.
//

#import "BDXLynxRevealViewInnerView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>

@implementation BDXRevealViewInnerView

@end

@implementation BDXLynxRevealViewInnerView

LYNX_REGISTER_UI("x-reveal-view-inner-right")

- (UIView*)createView {
    BDXRevealViewInnerView* view = [[BDXRevealViewInnerView alloc] init];
    return view;
}

- (void)insertChild:(LynxUI*)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
}

@end
