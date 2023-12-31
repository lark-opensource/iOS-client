//
//  BDXLynxBounceView.m
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import "BDXLynxBounceView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxPropsProcessor.h>
#import "LynxUI+BDXLynx.h"
#import <objc/runtime.h>

@implementation BDXLynxBounceView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bdx_inhibitParentLayout = YES;
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        self.bdx_inhibitParentLayout = YES;
    }
    return self;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-bounce-view")
#else
LYNX_REGISTER_UI("x-bounce-view")
#endif

@end
