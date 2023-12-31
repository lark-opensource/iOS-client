//
//  BDXLynxPageView.m
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import "BDXLynxPageView.h"
#import "BDXPageCategoryView.h"
#import "BDXPageContentView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXLynxPageViewItem.h"
#import "BDXPageGestureCollectionView.h"
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXLynxTabbarView.h"

@protocol BDXLynxPageViewDelegate <NSObject>

@optional
- (void)selectedPage:(NSDictionary *)info;
- (nullable UIView *)currentSelectedSubScrollView;
@end

NSString *const BDXPageCellID = @"BDXPageCell";

@interface BDXPageView () <BDXPageCategoryViewDelegate, BDXPageContentViewDelegate, BDXTabbarViewDelegate>

@property (nonatomic, strong) BDXLynxTabbar* lynxTabbar;

@property (nonatomic, strong) UIView* viewForTabbarOrCategory;
@property (nonatomic, strong) BDXPageCategoryView *categoryView;
@property (nonatomic, strong) BDXPageContentView *contentView;
@property (nonatomic, strong) NSLayoutConstraint *viewForTabbarOrCategoryHeightConstraint;
@property (nonatomic, weak) id<BDXLynxPageViewDelegate> lynxDelegate;
@property (nonatomic, assign) BOOL reloadingData;

@property (nonatomic) BOOL uiHasBeenSetup;
@property (nonatomic) BOOL categoryHasBeenLoaded;
@property (nonatomic) BOOL tabbarHasBeenLoaded;
@property (nonatomic) BOOL notFirstTimeReportSelecte;
- (void)setupUI;

@end

@implementation BDXPageView

- (BOOL) notFirstTimeReportSelecte {
    if(!_notFirstTimeReportSelecte){
        _notFirstTimeReportSelecte = YES;
        return NO;
    }
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)setupUI {
    if(self.uiHasBeenSetup){
        return;
    }
    [self loadViewForTabbarOrCategory];
    _categoryView = [[BDXPageCategoryView alloc] init];
    [self loadContentView];
    [self bringSubviewToFront:self.viewForTabbarOrCategory];
    self.uiHasBeenSetup = YES;
}

- (nullable NSArray<UIView *> *)tabContentViews {
    NSMutableArray<UIView *> *views = [NSMutableArray new];
    for (BDXLynxPageViewItem *i in self.datas) {
        UIView *scrollView = [i childScrollView];
        if (scrollView != nil) {
            [views addObject:scrollView];
        } else {
            if (i.view != nil) {
                [views addObject: i.view];
            }
        }
    }
    return views;
}

- (NSInteger)selected {
    return [[self contentView] selectedPage];
}

- (void)setDatas:(NSArray<BDXLynxPageViewItem *> *)datas {
    _datas = datas;
    [self loadData];
}

- (void)loadData {
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:_datas.count];
    for (BDXLynxPageViewItem *i in _datas) {
        [titles addObject:i.tag];
    }
    _categoryView.titles = titles;
    _contentView.pageItems = _datas;
}

- (void)updateCategoryView {
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:_datas.count];
    for (BDXLynxPageViewItem *i in _datas) {
        [titles addObject:i.tag];
    }
    _categoryView.titles = titles;
}

- (void)didSelectedPage:(NSInteger)index withScene:(NSString*)scene{
    if(index >= _datas.count) return;
    if(!self.notFirstTimeReportSelecte) scene = @"";
    NSDictionary *info = @{
        @"tag" : (_datas[index].tag == nil ? @"" : _datas[index].tag),
        @"index" : @(index),
        @"scene" : scene
    };
    [_lynxDelegate selectedPage:info];
}

#pragma mark - BDXTabbarViewDelegate

- (void)tabbarViewDidSelectedItemAtIndex:(NSInteger)index {
    if (self.reloadingData) {
        return;
    }
    self.reloadingData = YES;
    [self.contentView setSelectedPage:index animated:NO];
    if (index < [_datas count]) {
        [self didSelectedPage:index withScene:@"click"];
        [self.viewDelegate didSelectPage:_datas[index]];
    }
    self.reloadingData = NO;
}

#pragma mark - BDXPageCategoryViewDelegate
- (void)categoryViewDidChangeSelectIndex:(NSInteger)index {
    [self didSelectedPage:index withScene:@"click"];
}

- (void)categoryViewDidSelectedItemAtIndex:(NSInteger)index {
    if (self.reloadingData) {
        return;
    }
    self.reloadingData = YES;
    [self.categoryView layoutAndScrollToSelectedItem];
    [self.contentView setSelectedPage:index animated:NO];
    [self.categoryView scrollToTargetIndex:index sourceIndex:index percent:1.0];

    if (index < [_datas count]) {
        [self.viewDelegate didSelectPage:_datas[index]];
    }
    self.reloadingData = NO;
}

- (BOOL)categoryViewOtherScrollViewStopScroll {
    BDXPageGestureCollectionView * contentViewScrollViewOrigin = _contentView.collectionView;
    UIView * contentViewCurrentSubScrollViewOrigin = [_lynxDelegate currentSelectedSubScrollView];
    UIScrollView *contentViewScrollView = nil;
    UIScrollView *contentViewCurrentSubScrollView = nil;
    if([contentViewScrollViewOrigin isKindOfClass: [UIScrollView class]]){
        contentViewScrollView = (UIScrollView*)contentViewScrollViewOrigin;
    }
    if([contentViewCurrentSubScrollViewOrigin isKindOfClass: [UIScrollView class]]){
        contentViewCurrentSubScrollView = (UIScrollView*)contentViewCurrentSubScrollViewOrigin;
    }
    BOOL contentViewScrollViewScrollStop =  contentViewScrollView == nil ? YES : !contentViewScrollView.tracking && !contentViewScrollView.dragging && !contentViewScrollView.decelerating;
    BOOL contentViewCurrentSubScrollViewScrollStop = contentViewCurrentSubScrollView == nil ? YES : !contentViewCurrentSubScrollView.tracking && !contentViewCurrentSubScrollView.dragging && !contentViewCurrentSubScrollView.decelerating;
    return contentViewScrollViewScrollStop && contentViewCurrentSubScrollViewScrollStop;
}

#pragma mark - BDXPageContentViewDelegate

- (void)pageContentViewScrollingToTargetPage:(NSInteger)targetPage sourcePage:(NSInteger)sourcePage percent:(CGFloat)percent {
    if (self.reloadingData) {
        return;
    }
    self.reloadingData = YES;
    [self.categoryView scrollToTargetIndex:targetPage sourceIndex:sourcePage percent:percent];
    [self.lynxTabbar.view scrollToTargetIndex:targetPage sourceIndex:sourcePage percent:percent];
    
    if (percent == 1.0 && targetPage < [_datas count] && self.contentView.selectedPage != targetPage) {
        [self.contentView setSelectedPage:targetPage animated:NO];
        [self didSelectedPage:targetPage withScene:@"slide"];
        [self.viewDelegate didSelectPage:_datas[targetPage]];
    }
    self.reloadingData = NO;
}

- (CGFloat)associatedCategoryViewHeight {
    return self.categoryView.frame.size.height;
}

#pragma mark -

- (NSInteger)originalPage {
    return self.categoryView.originalIndex;
}

- (NSInteger)selectedPage {
    return self.categoryView.selectedIndex;
}

#pragma mark - UI

- (void)loadViewForTabbarOrCategory {
    _viewForTabbarOrCategory = [[UIView alloc] init];
    _viewForTabbarOrCategory.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_viewForTabbarOrCategory];

    NSLayoutConstraint *cLeft = [NSLayoutConstraint constraintWithItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                           constant:0.0];
    cLeft.active = YES;

    NSLayoutConstraint *cTop = [NSLayoutConstraint constraintWithItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                           constant:0.0];
    cTop.active = YES;

    NSLayoutConstraint *cRight = [NSLayoutConstraint constraintWithItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                          constant:0.0];
    cRight.active = YES;

    NSLayoutConstraint *cHeight = [NSLayoutConstraint constraintWithItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                           constant:BDXPageCategoryViewDefaultHeight];
    cHeight.active = YES;
    self.viewForTabbarOrCategoryHeightConstraint = cHeight;
}

- (void)loadTabbarView {
    if(self.tabbarHasBeenLoaded){
        self.lynxTabbar.view.frame = self.lynxTabbar.frame;
        NSLog(@"debug: self.lynxTabbar.view.bounds: (%f,%f,%f,%f)", self.lynxTabbar.view.bounds.origin.x, self.lynxTabbar.view.bounds.origin.y, self.lynxTabbar.view.bounds.size.width, self.lynxTabbar.view.bounds.size.height);
        return;
    }
    self.tabbarHasBeenLoaded = YES;
    self.lynxTabbar.view.delegate = self;
    self.lynxTabbar.view.frame = self.lynxTabbar.frame;
    [self.viewForTabbarOrCategory addSubview:self.lynxTabbar.view];
}

- (void)loadCategoryView {
    if(self.categoryHasBeenLoaded){
        return;
    }
    self.categoryHasBeenLoaded = YES;
    _categoryView.delegate = self;
    _categoryView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.viewForTabbarOrCategory addSubview:_categoryView];
    
    NSLayoutConstraint *cLeft = [NSLayoutConstraint constraintWithItem:self.categoryView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                           constant:0.0];
    cLeft.active = YES;

    NSLayoutConstraint *cTop = [NSLayoutConstraint constraintWithItem:self.categoryView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                           constant:0.0];
    cTop.active = YES;

    NSLayoutConstraint *cRight = [NSLayoutConstraint constraintWithItem:self.categoryView
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                          constant:0.0];
    cRight.active = YES;

    NSLayoutConstraint *cHeight = [NSLayoutConstraint constraintWithItem:self.categoryView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                           constant:0];
    cHeight.active = YES;
}

- (void)loadContentView {
    _contentView = [[BDXPageContentView alloc] init];
    _contentView.delegate = self;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_contentView];

    NSLayoutConstraint *cLeft = [NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                           constant:0.0];
    cLeft.active = YES;
    NSLayoutConstraint *cTop = [NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.viewForTabbarOrCategory
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                           constant:0.0];
    cTop.active = YES;

    NSLayoutConstraint *cRight = [NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                           constant:0.0];
    cRight.active = YES;

    NSLayoutConstraint *cBottom = [NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                           constant:0.0];
    cBottom.active = YES;
}

@end

@interface BDXLynxPageView () <BDXLynxPageViewDelegate, BDXPageItemViewSizeDelegate, BDXPageItemViewTagDelegate>

@property(nonatomic, strong, nonnull) NSMutableArray<BDXLynxPageViewItem *> *pageItems;
@property (nonatomic, assign) BOOL hasDataChanged;

@property (nonatomic, copy) NSString *background;
@property (nonatomic, assign) CGFloat selectedTextSize;
@property (nonatomic, copy) NSString *selectedTextColor;
@property (nonatomic, assign) CGFloat unSelectedTextSize;
@property (nonatomic, copy) NSString *unSelectedTextColor;
@property (nonatomic, copy) NSString *tabIndicatorColor;
@property (nonatomic, assign) BOOL hideIndicator;
@property (nonatomic, assign) CGFloat tabInterspace;
@property (nonatomic, assign) CGFloat tabIndicatorWidth;
@property (nonatomic, assign) CGFloat tabIndicatorHeight;
@property (nonatomic, assign) CGFloat tabHeight;
@property (nonatomic, copy) NSString *tabLayoutGravity;
@property (nonatomic, copy) NSString *textBoldMode;
@property (nonatomic, copy) NSString *onChange;
@property (nonatomic, assign) BOOL hideBottomBorder;
@property (nonatomic, assign) CGFloat bottomBorderHeight;
@property (nonatomic, assign) CGFloat bottomBorderWidth;
@property (nonatomic, assign) CGFloat bottomBorderMarginBottom;
@property (nonatomic, copy) NSString *bottomBorderColor;
@property (nonatomic, assign) NSInteger defaultSelected;

@property (nonatomic, assign) BOOL allowHorizontalBounce;

@end

@implementation BDXLynxPageView

- (BOOL)hasCustomLayout {
    return YES;
}

- (nullable UIView *)currentSelectedPageView {
    BDXLynxPageViewItem *i = [[self view] contentView].selectedPageItem;
    return [i childScrollView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pageItems = [[NSMutableArray alloc] init];
        _tabHeight = BDXPageCategoryViewDefaultHeight;
        _defaultSelected = 0;
    }
    return self;
}

- (UIView *)createView {
    BDXPageView *view = [[BDXPageView alloc] init];
    view.lynxDelegate = self;
    [view setupUI];
    return view;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    if ([child isKindOfClass:[BDXLynxTabbar class]]) {
        self.view.lynxTabbar = (BDXLynxTabbar *)child;
    }
    if ([child isKindOfClass:[BDXLynxPageViewItem class]]) {
        BDXLynxPageViewItem *item = (BDXLynxPageViewItem *)child;
        item.sizeDelegate = self;
        item.tagDelegate = self;
        [_pageItems insertObject:item atIndex:index + (self.view.lynxTabbar == nil ? 0 : -1)];
    }
    
    _hasDataChanged = YES;
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    [_pageItems removeObjectAtIndex:index + (self.view.lynxTabbar == nil ? 0 : -1)];
    [[self view] setDatas:_pageItems];
    _hasDataChanged = YES;
}

- (void)layoutDidFinished {
    if (_hasDataChanged) {
        if(self.view.lynxTabbar == nil) {
            [[self view] loadCategoryView];
            [[self view] setDatas:_pageItems];

    //        [[self view].categoryView setSelectedIndex:0];
            if (_defaultSelected >= 0) {
                self.view.categoryView.originalIndex = _defaultSelected;
                // 默认选中tab只作用1次
                _defaultSelected = -1;
            }
            [[self view].categoryView setNeedsLayout];
            [[self view].categoryView layoutIfNeeded];
        } else {
            [[self view] loadTabbarView];
            [[self view].lynxTabbar.view reselectSelectedIndex];
        }

        if (![UIDevice btd_isIPhoneXSeries]) {
            [[self view].contentView setNeedsLayout];
        }
        _hasDataChanged = NO;
    }
}

#pragma mark - Delegate

- (void)selectedPage:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (nullable UIView *)currentSelectedSubScrollView {
    return [self currentSelectedPageView];
}


- (void)pageItemViewDidChangeFrame:(UIView *)view {
    if ([[self.view viewDelegate] respondsToSelector:@selector(itemSizeDidChange:)]) {
        [[self.view viewDelegate] itemSizeDidChange:view];
    }
}

- (void)pageItemViewDidChangeContentSize:(UIScrollView *)scrollView {
    if ([[self.view viewDelegate] respondsToSelector:@selector(itemSizeDidChange:)]) {
        [[self.view viewDelegate] itemSizeDidChange:scrollView];
    }
}

- (void)tagDidChanged:(nonnull BDXPageItemView *)view {
    [self.view updateCategoryView];
}

#pragma mark - Lynx

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-viewpager")
#else
LYNX_REGISTER_UI("x-viewpager")
#endif

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    if ([self view].lynxTabbar == nil) {
        return [super hitTest:point withEvent:event];
    }
    CGPoint tp = [[self view] convertPoint:point toView:[self view].viewForTabbarOrCategory];
    if([[self view].viewForTabbarOrCategory pointInside:tp withEvent:event]) {
        return [[self view].lynxTabbar hitTest:tp withEvent:event];;
    } else {
        return [super hitTest:point withEvent:event];
    }
}


LYNX_PROP_SETTER("tabbar-background", tabbarBackground, NSString *) {
    [self.view.categoryView setBackgroundColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("background", background, NSString *) {
    [self.view.contentView setBackgroundColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("selected-text-size", selectedTextSize, int) {
    _selectedTextSize = value;
    UIFont *titleSelectedFont = self.view.categoryView.titleSelectedFont;
    [self.view.categoryView setTitleSelectedFont:[titleSelectedFont fontWithSize:value]];
}

LYNX_PROP_SETTER("selected-text-color", selectedTextColor, NSString *) {
    _selectedTextColor = value;
    [self.view.categoryView setTitleSelectedColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("unselected-text-size", unSelectedTextSize, int) {
    _unSelectedTextSize = value;
    UIFont *titleNomalFont = self.view.categoryView.titleNomalFont;
    [self.view.categoryView setTitleNomalFont:[titleNomalFont fontWithSize:value]];
}

LYNX_PROP_SETTER("unselected-text-color", unSelectedTextColor, NSString *) {
    _unSelectedTextColor = value;
    [self.view.categoryView setTitleNormalColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("tab-indicator-color", tabIndicatorColor, NSString *) {
    _tabIndicatorColor = value;
    [self.view.categoryView setVernierColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("hide-indicator", hideIndicator, BOOL) {
    _hideIndicator = value;
    [self.view.categoryView setIsVernierHide:value];
}

LYNX_PROP_SETTER("tab-inter-space", tabInterspace, int) {
    _tabInterspace = value;
    [self.view.categoryView setItemSpacing:value];
}

LYNX_PROP_SETTER("tab-padding-left", tabPaddingLeft, int) {
    UIEdgeInsets insets = [self.view.categoryView collectionInset];
    insets.left = value;
    [self.view.categoryView setCollectionInset:insets];
}

LYNX_PROP_SETTER("tab-padding-top", tabPaddingTop, int) {
    UIEdgeInsets insets = [self.view.categoryView collectionInset];
    insets.top = value;
    [self.view.categoryView setCollectionInset:insets];
}

LYNX_PROP_SETTER("tab-padding-bottom", tabPaddingBottom, int) {
    UIEdgeInsets insets = [self.view.categoryView collectionInset];
    insets.bottom = value;
    [self.view.categoryView setCollectionInset:insets];
}

LYNX_PROP_SETTER("tab-padding-right", tabPaddingRight, int) {
    UIEdgeInsets insets = [self.view.categoryView collectionInset];
    insets.right = value;
    [self.view.categoryView setCollectionInset:insets];
}

LYNX_PROP_SETTER("tab-layout-gravity", tabLayoutGravity, NSString *) {
    _tabLayoutGravity = value;
    LayoutGravity mode = Center;
    if([value isEqual: @"left"]) mode = Left;
    [self.view.categoryView setTabLayoutGravity: mode];
}

LYNX_PROP_SETTER("tab-indicator-width", tabIndicatorWidth, int) {
    _tabIndicatorWidth = value;
    [self.view.categoryView setVernierWidth: value];
}

LYNX_PROP_SETTER("tab-indicator-height", tabIndicatorHeight, int) {
    _tabIndicatorHeight = value;
    [self.view.categoryView setVernierHeight: value];
}

LYNX_PROP_SETTER("text-bold-mode", textBoldMode, NSString *) {
    BoldMode mode = All;
    if([value isEqual: @"selected"]) mode = Selected;
    else if([value isEqual: @"unselected"]) mode = Unselected;
    [self.view.categoryView setTabBoldMode: mode];
}

LYNX_PROP_SETTER("tab-height", tabHeight , CGFloat) {
    _tabHeight = value;
    self.view.viewForTabbarOrCategoryHeightConstraint.constant = value;
    [self.view.categoryView setHeight: value];
    [self.view.categoryView resetTo0State];
    _hasDataChanged = YES;
}

LYNX_PROP_SETTER("border-top", bottomBorderMarginBottom, CGFloat) {
    _bottomBorderMarginBottom = value;
    [self.view.categoryView setBottomBorderMarginBottom:value];
    [self.view.lynxTabbar.view setBorderDistanceToBottom:value];
}

LYNX_PROP_SETTER("border-height", bottomBorderHeight, CGFloat) {
    _bottomBorderHeight = value;
    self.view.categoryView.bottomBorderHeight = value;
}

LYNX_PROP_SETTER("border-width", bottomBorderWidth, CGFloat) {
    _bottomBorderWidth = value;
    self.view.categoryView.bottomBorderWidth = value;
}

LYNX_PROP_SETTER("border-color", bottomBorderColor, NSString *) {
    _bottomBorderColor = value;
    [self.view.categoryView setBottomBorderColor:[UIColor btd_colorWithHexString:value]];
}

LYNX_PROP_SETTER("hide-border", hideBottomBorder, BOOL) {
    _hideBottomBorder = value;
    self.view.categoryView.isBottomBorderHide = value;
}

LYNX_PROP_SETTER("select-index", defaultSelected, int) {
    _defaultSelected = value;
    _hasDataChanged = YES;
}

LYNX_PROP_SETTER("allow-horizontal-bounce", allowHorizontalBounce, BOOL) {
    _allowHorizontalBounce = value;
    self.view.contentView.collectionView.bounces = value;
    self.view.contentView.collectionView.alwaysBounceHorizontal = value;
}

LYNX_PROP_SETTER("reserve-edgeback", reserveEdgeBack, BOOL) {
//    _reserveEdgeBack = value;
//    self.view.contentView.collectionView.needReserveEdgeBack = value;
    self.view.contentView.collectionView.bounces = !value;
}

LYNX_UI_METHOD(selectTab) {
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"index"]) {
        NSInteger index = [[params objectForKey:@"index"] intValue];
        if([self.view.categoryView directSetSelectedIndex:index]){
            success = YES;
            msg = @"";
        }else{
            success = NO;
            msg = @"index out of bounds";
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
