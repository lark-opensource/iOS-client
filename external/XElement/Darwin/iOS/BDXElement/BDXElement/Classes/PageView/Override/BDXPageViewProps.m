//
//  BDXPageCategoryViewModel.m
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import "BDXPageViewProps.h"

@implementation BDXPageViewProps

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tabbarBackground = [UIColor clearColor];
        _selectedTextSize = 14;
        _selectTextColor = [UIColor blackColor];
        _unSelectTextColor = [UIColor blackColor];
        _unSelectedTextSize = 14;
        _tabIndicatorColor = [UIColor colorWithRed:105/255.0 green:144/255.0 blue:239/255.0 alpha:1];
        _tabInterSpace = 5;
        _layoutGravity = BDXTabLayoutGravityCenter;
        _tabIndicatorWidth = 20;
        _tabIndicatorHeight = 2;
        _hideIndicator = false;
        _tabPaddingLeft = BDXCategoryViewAutomaticDimension;
        _tabPaddingRight = BDXCategoryViewAutomaticDimension;
        _tabHeight = 60;
        _borderTop = 0;
        _borderWidth = 0;
        _borderColor = [UIColor clearColor];
        _borderHeight = 0;
        _hideBorder = true;
        _selectIndex = 0;
        _allowHorizontalBounce = false;
        _reserveEdgeback = false;
        _tabIndicatorRadius = BDXCategoryViewAutomaticDimension;
        _textBoldMode = @"none";
        _allowHorizontalGesture = YES;
    }
    return self;
}

@end
