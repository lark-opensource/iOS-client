//
//  BDXLynxFoldViewBarPro.m
//  BDXElement
//
//  Created by bytedance on 2020/10/28.
//

#import "BDXLynxFoldViewBarPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@interface BDXLynxFoldViewBarPro ()

@end

@implementation BDXLynxFoldViewBarPro

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-toolbar-pro")
#else
LYNX_REGISTER_UI("x-foldview-toolbar-pro")
#endif

- (UIView*)createView {
    UIView* view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

@end
