//
//  BDXLynxTabbarItemPro.m
//  BDXElement
//
//  Created by hanzheng on 2021/3/17.
//

#import "BDXLynxTabbarItemPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

CGFloat const kBDXTabbarItemProViewFloatComparisonEpsilon = 0.5;

@implementation BDXTabbarItemProView

- (void)setFrame:(CGRect)frame {
    //we pick the BDXTabbarItemProView as a cell in BDXtabBarCatogoryView, so the origin value should always be (0,0).
    CGRect newFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    CGRect oldFrame = self.frame;
    [super setFrame:newFrame];
    if (fabs(newFrame.size.width - oldFrame.size.width) > kBDXTabbarItemProViewFloatComparisonEpsilon ) {
        [_delegate widthDidChanged:self];
    }
}

@end

@implementation BDXLynxTabbarItemPro

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selected = false;
    }
    return self;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-tabbar-item-pro")
#else
LYNX_REGISTER_UI("x-tabbar-item-pro")
#endif

- (BDXTabbarItemProView *)createView {
    BDXTabbarItemProView* view = [[BDXTabbarItemProView alloc] init];
    return view;
}

LYNX_PROP_SETTER("select", select, BOOL) {
    _selected = value;
    if (self.selectedBlock) {
        self.selectedBlock(value);
    }
}

LYNX_PROP_SETTER("tag", tabTag, NSString *) {
    _tabTag = value;
}

@end
