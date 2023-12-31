//
//  BDXLynxFoldViewItem.m
//  BDXElement
//
//  Created by AKing on 2020/9/24.
//

#import "BDXLynxFoldViewItem.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@interface BDXLynxFoldViewItem ()

@end

@implementation BDXLynxFoldViewItem

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-header")
#else
LYNX_REGISTER_UI("x-foldview-header")
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
