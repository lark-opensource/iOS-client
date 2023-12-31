//
//  BDXLynxPageViewPro.m
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import "BDXLynxPageViewPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxViewCurrentIndexHelper.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXPageIndicatorView.h"
#import "BDXPageViewProps.h"
#import "BDXLynxTabBarPro.h"
#import "BDXTabBarCategoryView.h"

#define ONE_WIDTH_UNIT ([UIScreen mainScreen].bounds.size.width / 375.0)

@interface BDXLynxPageViewPro () <BDXPageBaseViewDelegate, BDXPageItemViewProTagDelegate, BDXTabBarProTagDelegate, LynxViewCurrentIndexHelper>

@property(nonatomic, strong, nonnull) NSMutableArray<BDXLynxPageViewItemPro *> *pageItems;
@property(nonatomic, strong) BDXLynxTabBarPro* tabbar;
@property (nonatomic, assign) BOOL hasDataChanged;
@property (nonatomic, strong) BDXPageViewProps* props;
@property (nonatomic, assign) BOOL propsDidSet;
@property (nonatomic, assign) BOOL defaulSelectIndexDidSet;
@property (nonatomic, assign) BOOL viewpagerDynamic;
@end

@implementation BDXLynxPageViewPro

- (instancetype)init {
    self = [super init];
    if (self) {
        _pageItems = [[NSMutableArray alloc] init];
        _props = [[BDXPageViewProps alloc] init];
        _propsDidSet = false;
        _defaulSelectIndexDidSet = false;
    }
    return self;
}

- (UIView *)createView {
    BDXPageBaseView *view = [[BDXPageBaseView alloc] init];
//    BDXPageIndicatorView *view = [[BDXPageIndicatorView alloc] init];
    view.delegate = self;
    return view;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
    if ([child isKindOfClass:[BDXLynxPageViewItemPro class]]) {
        BDXLynxPageViewItemPro *item = (BDXLynxPageViewItemPro *)child;
        item.tagDelegate = self;
        if (self.viewpagerDynamic) {
            [_pageItems insertObject:item atIndex:_tabbar ? (index - 1) : index];
        } else {
          [_pageItems addObject:item];
        }
    } else if ([child isKindOfClass:BDXLynxTabBarPro.class]) {
        _tabbar = (BDXLynxTabBarPro *)child;
        _tabbar.tagDelegate = self;
    }
    _hasDataChanged = YES;
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    if ([child isKindOfClass:[BDXLynxPageViewItemPro class]]) {
        BDXLynxPageViewItemPro *item = (BDXLynxPageViewItemPro *)child;
        [_pageItems removeObject:item];
    } else if ([child isKindOfClass:[BDXLynxTabBarPro class]]) {
        _tabbar = nil;
    }
    _hasDataChanged = YES;
}

- (void)layoutDidFinished {
    if (!_propsDidSet) {
        [self setupProps];
        _propsDidSet = true;
    }
    if (_hasDataChanged) {
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:_pageItems.count];
        for (BDXLynxPageViewItemPro *i in _pageItems) {
            NSString *tag = (i.tag == nil) ? @"" : i.tag;
            [titles addObject:tag];
        }
        //先设置title数据源，再加载view
        [[self view] setTitles:titles];
        [[self view].categoryView reloadData];
        [[self view] loadView];
        if ([self.view.listContainerView isKindOfClass:UIView.class]) {
            UIView *view = (UIView *)self.view.listContainerView;
            view.backgroundColor = self.view.backgroundColor;
        }
        _hasDataChanged = NO;
    }
    if (_tabbar) {
        self.view.categoryViewHeight = _tabbar.frame.size.height;
    }
    [self.view.listContainerView setRTL:self.isRtl];
}

- (void)setupProps {
    //Do not use custom tabbar
    if (_tabbar == nil) {
        BDXCategoryTitleView* titleView = [[BDXCategoryTitleView alloc] init];
        self.view.categoryView = titleView;
        [self updateProps];
    } else { //use custom tabbar
        _tabbar.view.delegate = self;
        self.view.categoryView = _tabbar.view;
        [self updateProps];
    }
}

- (void)updatePropsIfNeed {
    if (_propsDidSet) {
        [self updateProps];
    }
}

- (void)updateProps {
    if (_tabbar == nil) {
        BDXCategoryTitleView* titleView = (BDXCategoryTitleView*)self.view.categoryView;
        titleView.backgroundColor = _props.tabbarBackground;
        if([_props.textBoldMode isEqualToString: @"selected"] || [_props.textBoldMode isEqualToString: @"all"]) {
            titleView.titleSelectedFont = [UIFont systemFontOfSize:_props.selectedTextSize weight:UIFontWeightBold];
        } else {
            titleView.titleSelectedFont = [UIFont systemFontOfSize:_props.selectedTextSize];
        }
        titleView.titleSelectedColor = _props.selectTextColor;
        if([_props.textBoldMode isEqualToString: @"unselected"] || [_props.textBoldMode isEqualToString: @"all"]) {
            titleView.titleFont = [UIFont systemFontOfSize:_props.unSelectedTextSize weight:UIFontWeightBold];
        } else {
            titleView.titleFont = [UIFont systemFontOfSize:_props.unSelectedTextSize];
        }
        titleView.titleColor = _props.unSelectTextColor;
        BDXCategoryIndicatorLineView *lineView = [[BDXCategoryIndicatorLineView alloc] init];
        lineView.indicatorColor = _props.tabIndicatorColor;
        titleView.indicators = _props.hideIndicator ? @[] : @[lineView];
        titleView.cellSpacing = _props.tabInterSpace;
        titleView.layoutGravity = _props.layoutGravity;
        lineView.indicatorWidth = _props.tabIndicatorWidth;
        lineView.indicatorHeight = _props.tabIndicatorHeight;
        lineView.indicatorCornerRadius = _props.tabIndicatorRadius;
        titleView.contentEdgeInsetLeft = _props.tabPaddingLeft;
        titleView.contentEdgeInsetRight = _props.tabPaddingRight;
        self.view.categoryViewHeight = _props.tabHeight;
        titleView.bottomBorderConfig.margin = _props.borderTop;
        titleView.bottomBorderConfig.width = _props.borderWidth;
        titleView.bottomBorderConfig.height = _props.borderHeight;
        titleView.bottomBorderConfig.color = _props.borderColor;
        titleView.bottomBorderConfig.hidden = _props.hideBorder;
        titleView.defaultSelectedIndex = _props.selectIndex;
        titleView.listContainer.contentScrollView.bounces = _props.allowHorizontalBounce;
        titleView.listContainer.contentScrollView.alwaysBounceHorizontal = _props.allowHorizontalBounce;
        titleView.listContainer.contentScrollView.bounces = _props.reserveEdgeback;
        if (_propsDidSet) {
            [titleView reloadDataWithoutListContainer];
        }
    } else {
        self.view.categoryViewHeight = _tabbar.frame.size.height;
        if (_propsDidSet) {
            [_tabbar.view reloadDataWithoutListContainer];
        } else {
            if (_defaulSelectIndexDidSet) {
                _tabbar.view.defaultSelectedIndex = _props.selectIndex;
            }
        }
    }
    [self.view.listContainerView setHorizonScrollEnable:_props.allowHorizontalGesture];
  if ([self.view.listContainerView respondsToSelector:@selector(setGestureDirection:)]){
    [self.view.listContainerView setGestureDirection:_props.gestureDirection];
  }
  if ([self.view.listContainerView respondsToSelector:@selector(setLynxView:)]){
    [self.view.listContainerView setLynxView:self.context.rootView];
  }
  if ([self.view.listContainerView respondsToSelector:@selector(setGestureBeginOffset:)]){
    [self.view.listContainerView setGestureBeginOffset:_props.gestureBeginOffset];
  }
  if (self.viewpagerDynamic) {
    if ([self.view.listContainerView respondsToSelector:@selector(enableDynamicPage)]) {
      [self.view.listContainerView performSelector:@selector(enableDynamicPage)];
    }
  }
}

- (BOOL)hasCustomLayout {
    return YES;
}
#pragma mark - BDXPageItemViewProTagDelegate
- (void)tagDidChanged:(nonnull BDXPageItemViewPro *)view {
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:_pageItems.count];
    for (BDXLynxPageViewItemPro *i in _pageItems) {
        [titles addObject:i.tag];
    }
    [[self view] setTitles:titles];
    [[self view].categoryView reloadDataWithoutListContainer];
}

#pragma mark - BDXTabBarProTagDelegate
- (void)tabBarTagDidChanged {
    [[self view].categoryView reloadDataWithoutListContainer];
    [self.tagDelegate lynxPageViewLayoutIfNeeded];
}

#pragma mark - BDXPageBaseViewDelegate

- (BOOL)viewpagerIsDynamic {
  return self.viewpagerDynamic;
}

- (id<BDXCategoryListContentViewDelegate>)listContainerView:(BDXCategoryListContainerView *)listContainerView initListForIndex:(NSInteger)index {
    BDXLynxPageViewItemPro *i = [_pageItems objectAtIndex:index];
    return i.view;
}

- (NSInteger)numberOfListsInlistContainerView:(BDXCategoryListContainerView *)listContainerView {
    return _pageItems.count;
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index {
    [self didSelectedPage:index withScene:@"slide"];
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView didClickSelectedItemAtIndex:(NSInteger)index {
    [self didSelectedPage:index withScene:@"click"];
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    LynxCustomEvent *appearEvent =
        [[LynxDetailEvent alloc] initWithName:@"tabbarcellappear"
                                   targetSign:[self sign]
                                       detail:@{@"position" : @(indexPath.row)}];
    [self.context.eventEmitter sendCustomEvent:appearEvent];
}

-(void)categoryView:(BDXCategoryBaseView *)categoryView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    LynxCustomEvent *disAppearEvent =
        [[LynxDetailEvent alloc] initWithName:@"tabbarcelldisappear"
                                   targetSign:[self sign]
                                       detail:@{@"position" : @(indexPath.row)}];
    [self.context.eventEmitter sendCustomEvent:disAppearEvent];
}

- (void)listContainerViewDidScroll:(UIScrollView *)scrollView {
    NSString *index = [NSString stringWithFormat:@"%.2f",scrollView.contentOffset.x/scrollView.frame.size.width];
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"offsetchange" targetSign:[self sign] detail:@{@"offset":index}];
    [self.context.eventEmitter sendCustomEvent:event];
}

#pragma mark - Private

- (void)didSelectedPage:(NSInteger)index withScene:(NSString*)scene {
    if(index >= _pageItems.count) return;
    NSDictionary *info = @{
        @"tag" : (_pageItems[index].tag == nil ? @"" : _pageItems[index].tag),
        @"index" : @(index),
        @"scene" : scene
    };
    
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

#pragma mark - Lynx

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-viewpager-pro")
#else
LYNX_REGISTER_UI("x-viewpager-pro")
#endif

//- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    if (self.view.categoryView.selectedIndex < _pageItems.count) {
//        BDXLynxPageViewItemPro *item = _pageItems[self.view.categoryView.selectedIndex];
//        LynxUI *hit = [item hitTest:point withEvent:event];
//        return hit;
//    } else {
//        return [super hitTest:point withEvent:event];
//    }
//}

-(int)getCurrentIndex {
    return (int)[[[self view]listContainerView]currentIndex];
}

//tabbar settings
LYNX_PROP_SETTER("tabbar-background", tabbarBackground, NSString *) {
    _props.tabbarBackground = [UIColor btd_colorWithHexString:value];
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("selected-text-size", selectedTextSize, int) {
    _props.selectedTextSize = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("selected-text-color", selectedTextColor, NSString *) {
    _props.selectTextColor =[UIColor btd_colorWithHexString:value];
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("unselected-text-size", unSelectedTextSize, int) {
    _props.unSelectedTextSize = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("unselected-text-color", unSelectedTextColor, NSString *) {
    _props.unSelectTextColor = [UIColor btd_colorWithHexString:value];
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-indicator-color", tabIndicatorColor, NSString *) {
    _props.tabIndicatorColor = [UIColor btd_colorWithHexString:value];
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("hide-indicator", hideIndicator, BOOL) {
    _props.hideIndicator = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-inter-space", tabInterspace, int) {
    _props.tabInterSpace = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-layout-gravity", tabLayoutGravity, NSString *) {
    if([value isEqualToString: @"left"]) {
        _props.layoutGravity = BDXTabLayoutGravityLeft;
    } else if ([value isEqualToString:@"center"]) {
        _props.layoutGravity = BDXTabLayoutGravityCenter;
    } else if ([value isEqualToString:@"fill"]) {
        _props.layoutGravity = BDXTabLayoutGravityFill;
    }
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-indicator-width", tabIndicatorWidth, int) {
    _props.tabIndicatorWidth = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-indicator-height", tabIndicatorHeight, int) {
    _props.tabIndicatorHeight = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-padding-left", tabPaddingLeft, CGFloat) {
    _props.tabPaddingLeft = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-padding-right", tabPaddingRight, CGFloat) {
    _props.tabPaddingRight = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("tab-height", tabHeight , CGFloat) {
    _props.tabHeight = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("text-bold-mode", textBoldMode, NSString *) {
    _props.textBoldMode = value;
}

LYNX_PROP_SETTER("border-top", bottomBorderMarginBottom, CGFloat) {
    _props.borderTop = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("border-height", bottomBorderHeight, CGFloat) {
    _props.borderHeight = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("border-width", bottomBorderWidth, CGFloat) {
    _props.borderWidth = value * ONE_WIDTH_UNIT;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("border-color", bottomBorderColor, NSString *) {
    _props.borderColor = [UIColor btd_colorWithHexString:value];
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("hide-border", hideBottomBorder, BOOL) {
    _props.hideBorder = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("select-index", defaultSelected, int) {
    _props.selectIndex = value;
    _defaulSelectIndexDidSet = true;
}

LYNX_PROP_SETTER("allow-horizontal-bounce", allowHorizontalBounce, BOOL) {
    _props.allowHorizontalBounce = value;
}

LYNX_PROP_SETTER("reserve-edgeback", reserveEdgeBack, BOOL) {
    _props.reserveEdgeback = value;
}

LYNX_PROP_SETTER("tab-indicator-radius", tabIndicatorRadius, CGFloat) {
    _props.tabIndicatorRadius = value;
}

LYNX_PROP_SETTER("allow-horizontal-gesture", allowHorizontalGesture, BOOL) {
    _props.allowHorizontalGesture = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("ios-gesture-direction", gestureDirection, int) {
    _props.gestureDirection = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("ios-gesture-offset", gestureOffset, CGFloat) {
    _props.gestureBeginOffset = value;
    [self updatePropsIfNeed];
}

LYNX_PROP_SETTER("viewpager-dynamic", setViewpagerDynamic, BOOL) {
    self.viewpagerDynamic = value;
}

LYNX_UI_METHOD(selectTab) {
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"index"]) {
        NSInteger index = [[params objectForKey:@"index"] intValue];
        if (index < 0 || index >= _pageItems.count) {
            success = NO;
            msg = @"index out of bounds";
        } else {
            [self.view.categoryView selectItemAtIndex:index];
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
