//
//  BDXLynxTabbarItemView.m
//  Lynx
//
//  Created by bytedance on 2020/12/1.
//

#import "BDXLynxTabbarItemView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@implementation BDXTabbarItemView
@end

@interface BDXLynxTabbarItemView ()
@property (nonatomic) NSString *tabTag;
@end

@implementation BDXLynxTabbarItemView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-tabbar-item")
#else
LYNX_REGISTER_UI("x-tabbar-item")
#endif

- (UIView *)createView {
    BDXTabbarItemView* view = [[BDXTabbarItemView alloc] init];
    return view;
}

- (void)insertChild:(LynxUI*)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
}

LYNX_PROP_SETTER("tag", tabTag, NSString *) {
    _tabTag = value;
    [self view].tabTag = value;
}

@end
