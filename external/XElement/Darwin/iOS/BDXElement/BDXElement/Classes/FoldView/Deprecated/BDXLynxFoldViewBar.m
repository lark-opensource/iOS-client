//
//  BDXLynxFoldViewBar.m
//  BDXElement
//
//  Created by bytedance on 2020/10/28.
//

#import "BDXLynxFoldViewBar.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@interface BDXLynxFoldViewBar ()

@end

@implementation BDXLynxFoldViewBar

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-toolbar")
#else
LYNX_REGISTER_UI("x-foldview-toolbar")
#endif

- (UIView*)createView {
    UIView* view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
}

@end
