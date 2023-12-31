//
//  BDXLynxTabBarPro.m
//  BDXElement
//
//  Created by hanzheng on 2021/3/17.
//

#import "BDXLynxTabBarPro.h"
#import "BDXLynxTabbarItemPro.h"
#import "BDXCategoryIndicatorLineView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <Lynx/LynxUIMethodProcessor.h>

@interface BDXLynxTabBarPro()

@property (nonatomic) BOOL hasDataChanged;
@property (nonatomic) BDXCategoryIndicatorLineView *lineView;
@property (nonatomic) NSString *tabLayoutGravity;
@property (nonatomic) CGFloat tabInterSpace;
@property (nonatomic) UIColor *tabIndicatorColor;
@property (nonatomic) CGFloat tabIndicatorWidth;
@property (nonatomic) CGFloat tabIndicatorHeight;
@property (nonatomic) CGFloat tabIndicatorTop;
@property (nonatomic) CGFloat borderHeight;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) CGFloat borderMarginBottom;
@property (nonatomic) UIColor *borderColor;
@property (nonatomic) UIColor *tabbarBackground;
@property (nonatomic, assign) BOOL hideIndicator;


@end

@implementation BDXLynxTabBarPro

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tabItems = [NSMutableArray new];
        _hideIndicator = false;
        _tabIndicatorColor = UIColor.redColor;
        _tabInterSpace = 0;
        _tabIndicatorWidth = 40;
        _tabIndicatorHeight = 1;
    }
    return self;
}

- (UIView *)createView {
    BDXTabBarCategoryView* view = [[BDXTabBarCategoryView alloc] init];
    view.lynxTabbar = self;
    _lineView = [[BDXCategoryIndicatorLineView alloc] init];
    _lineView.indicatorColor = _tabIndicatorColor;
    _lineView.indicatorWidth = _tabIndicatorWidth;
    _lineView.indicatorHeight = _tabIndicatorHeight;
    view.indicators =  _hideIndicator ? @[] : @[_lineView];
    return view;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    if([child isKindOfClass:[BDXLynxTabbarItemPro class]]) {
        BDXLynxTabbarItemPro *item = (BDXLynxTabbarItemPro *)child;
        [self.tabItems insertObject:item atIndex:index];
        if (item.selected) {
            self.view.defaultSelectedIndex = index;
        }
        __weak typeof(self)weakSelf = self;
        [item setSelectedBlock:^(BOOL selected) {
            if (selected && index >= 0 && index < weakSelf.tabItems.count) {
                [weakSelf.view selectItemAtIndex:index];
            }
        }];
    }
    self.hasDataChanged = YES;
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    if([child isKindOfClass:[BDXLynxTabbarItemPro class]]) {
        [self.tabItems removeObjectAtIndex:index];
    }
    self.hasDataChanged = YES;
}

- (void)propsDidUpdate {
    [self.view reloadDataWithoutListContainer];
}

- (void)layoutDidFinished {
    if (_hasDataChanged) {
        _hasDataChanged = NO;
        [self.view reloadData];
        [self.tagDelegate tabBarTagDidChanged];
    }
    self.view.isRTL = self.isRtl;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-tabbar-pro")
#else
LYNX_REGISTER_UI("x-tabbar-pro")
#endif

//tabbar settings
LYNX_PROP_SETTER("tabbar-background", tabbarBackground, NSString *) {
    _tabbarBackground = [UIColor btd_colorWithHexString:value];
    self.view.backgroundColor = _tabbarBackground;
}

LYNX_PROP_SETTER("tab-layout-gravity", tabLayoutGravity, NSString *) {
    _tabLayoutGravity = value;
    if([value isEqualToString: @"left"]) {
        self.view.layoutGravity = BDXTabLayoutGravityLeft;
    } else if ([value isEqualToString:@"center"]) {
        self.view.layoutGravity = BDXTabLayoutGravityCenter;
    } else if ([value isEqualToString:@"fill"]) {
        self.view.layoutGravity = BDXTabLayoutGravityFill;
    }
}

LYNX_PROP_SETTER("tab-inter-space", tabInterSpace, CGFloat) {
    _tabInterSpace = value;
    self.view.cellSpacing = value;
}

LYNX_PROP_SETTER("tab-indicator-top", tabIndicatorTop, CGFloat) {
    _lineView.verticalMargin = value;
}

LYNX_PROP_SETTER("tab-indicator-color", tabIndicatorColor, NSString *) {
    _tabIndicatorColor = [UIColor btd_colorWithHexString:value];
    _lineView.indicatorColor = _tabIndicatorColor;
}

LYNX_PROP_SETTER("tab-indicator-width", tabIndicatorWidth, CGFloat) {
    _tabIndicatorWidth = value;
    _lineView.indicatorWidth = value;
}

LYNX_PROP_SETTER("tab-indicator-height", tabIndicatorHeight, CGFloat) {
    _tabIndicatorHeight = value;
    _lineView.indicatorHeight = value;
}

LYNX_PROP_SETTER("tab-indicator-radius", tabIndicatorRadius, CGFloat) {
    _lineView.indicatorCornerRadius = value;
}

LYNX_PROP_SETTER("border-color", borderColor, NSString *) {
    _borderColor = [UIColor btd_colorWithHexString:value];
    self.view.bottomBorderConfig.color = _borderColor;
}

LYNX_PROP_SETTER("border-width", borderWidth, CGFloat) {
    _borderWidth = value;
    self.view.bottomBorderConfig.width = value;
}

LYNX_PROP_SETTER("border-height", borderHeight, CGFloat) {
    _borderHeight = value;
    self.view.bottomBorderConfig.height = value;
}

LYNX_PROP_SETTER("border-top", borderMarginBottom, CGFloat) {
    _borderMarginBottom = value;
    self.view.bottomBorderConfig.margin = _borderMarginBottom;
}

LYNX_PROP_SETTER("hide-border", hideBottomBorder, BOOL) {
    self.view.bottomBorderConfig.hidden = value;
}

LYNX_PROP_SETTER("hide-indicator", hideIndicator, BOOL) {
    _hideIndicator = value;
    self.view.indicators =  _hideIndicator ? @[] : @[_lineView];
}

LYNX_PROP_SETTER("tab-padding-left", tabPaddingLeft, CGFloat) {
    self.view.contentEdgeInsetLeft = value;
}

LYNX_PROP_SETTER("tab-padding-right", tabPaddingRight, CGFloat) {
    self.view.contentEdgeInsetRight = value;
}


LYNX_UI_METHOD(selectTab) {
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"index"]) {
        NSInteger index = [[params objectForKey:@"index"] intValue];
        if (index < 0 || index >= _tabItems.count) {
            success = NO;
            msg = @"index out of bounds";
        } else {
            [self.view selectItemAtIndex:index];
            success = YES;
            msg = @"";
        }
    }else{
        success = NO;
        msg = @"no index key";
    }
    callback(
      kUIMethodSuccess, @{
          @"success": @(success),
          @"msg": msg,
      });
}

@end
