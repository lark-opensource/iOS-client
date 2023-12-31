//
//  BDXLynxFoldViewPro.m
//  BDXElement
//
//  Created by AKing on 2020/9/24.
//

#import "BDXLynxFoldViewPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import "BDXLynxFoldHeaderViewPro.h"
#import "BDXLynxPageViewPro.h"
#import "BDXLynxFoldViewBarPro.h"
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/UIView+Lynx.h>
#import <math.h>
#import "BDXPagerView.h"
#import "BDXPagerListRefreshView.h"
#import <Lynx/LynxEventEmitter.h>
#import "BDXLynxRefreshViewConfigInject.h"
#import "UIView+BDXElementNativeView.h"

typedef NS_ENUM(NSInteger, FoldViewRefreshMode) {
    FoldViewRefreshModeNone,
    FoldViewRefreshModeFold,
    FoldViewRefreshModePage
};

@protocol BDXFoldViewProDelegate <NSObject>

- (NSUInteger)foldViewHeaderViewHeight;
- (id<BDXPagerViewListViewDelegate>)foldView:(BDXPagerView *)pagerView initListAtIndex:(NSInteger)index;
- (void)foldView:(BDXPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView;
- (void)foldView:(BDXPagerView *)pagerView listScrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface BDXFoldViewPro () <BDXPagerViewDelegate, BDXPagerMainTableViewGestureDelegate, BDXLynxRefreshViewConfigInject>

@property (nonatomic, strong) BDXPagerView *foldView;
@property (nonatomic, strong) BDXPageBaseView *pageView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, assign) CGFloat pinSectionHeaderOffset;

@property (nonatomic, weak) id<BDXFoldViewProDelegate> delegate;
@property (nonatomic, copy) BDXLynxRefreshViewInjectBlock refreshViewInjectBlock;

@end

@implementation BDXFoldViewPro

- (void)setupFoldView:(BOOL)pageRefresh
      scrollBarEnable:(BOOL)scrollBarEnable
  allowVerticalBounce:(BOOL)allowVerticalBounce
                isRTL:(BOOL)isRTL {
    [self.foldView removeFromSuperview];
    if (pageRefresh) {
        self.foldView = [[BDXPagerListRefreshView alloc] initWithDelegate:self];
    } else {
        self.foldView = [[BDXPagerView alloc] initWithDelegate:self];
    }
    [self.foldView.listContainerView setRTL:isRTL];
    self.foldView.pinSectionHeaderVerticalOffset = self.pinSectionHeaderOffset;
    self.foldView.automaticallyDisplayListVerticalScrollIndicator = scrollBarEnable;
    self.foldView.mainTableView.gestureDelegate = self;
    self.foldView.mainTableView.bounces = allowVerticalBounce;
    self.foldView.mainTableView.alwaysBounceVertical = allowVerticalBounce;
    NSAssert(self.pageView, @"BDXFoldViewPro pageview can not be nil");
    //The background color of the listContainerView is controlled by the pageview background color, and the pageview defaults to a white background color
    self.foldView.listContainerView.backgroundColor = self.pageView.backgroundColor;
    self.pageView.listContainerView = (id<BDXCategoryViewListContainer>)self.foldView.listContainerView;
  if ([self.pageView.delegate respondsToSelector:@selector(viewpagerIsDynamic)]) {
    if ([self.pageView.delegate viewpagerIsDynamic]) {
      if ([self.pageView.listContainerView respondsToSelector:@selector(enableDynamicPage)]) {
        [self.pageView.listContainerView performSelector:@selector(enableDynamicPage)];
      }
    }
  }
    self.pageView.hidden = YES;
    [self addSubview:self.foldView];
    [self addSubview: self.barView];
    [self setupRefreshViewIfNeeded];
    [self setupViewsName];
    [self.foldView reloadData];
    
    // Something weird, there's a probability of it happening in system before iOS14
    // layoutSubviews is not being called after calling addSubview
    // so we manually call it
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.foldView.frame.size, self.bounds.size)) {
        self.foldView.frame = self.bounds;
    }
}

- (void)setupRefreshViewIfNeeded {
    if (self.refreshViewInjectBlock) {
        self.refreshViewInjectBlock(self.foldView.mainTableView);
    }
}

- (void)setupViewsName {
    [self.foldView.mainTableView setBdx_nativeViewName:@"mainTableView"];
}

#pragma mark - BDXPagerViewDelegate

- (UIView *)tableHeaderViewInPagerView:(BDXPagerView *)pagerView {
    return self.headerView;
}

- (NSUInteger)tableHeaderViewHeightInPagerView:(BDXPagerView *)pagerView {
    return [self.delegate foldViewHeaderViewHeight];;
}

- (NSUInteger)heightForPinSectionHeaderInPagerView:(BDXPagerView *)pagerView {
    return self.pageView.categoryViewHeight;//
}

- (UIView *)viewForPinSectionHeaderInPagerView:(BDXPagerView *)pagerView {
    return self.pageView.categoryView;
}

- (NSInteger)numberOfListsInPagerView:(BDXPagerView *)pagerView {
    return self.pageView.titles.count;
}

- (id<BDXPagerViewListViewDelegate>)pagerView:(BDXPagerView *)pagerView initListAtIndex:(NSInteger)index {
    return [self.delegate foldView:pagerView initListAtIndex:index];
}

- (void)pagerView:(BDXPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView {
    [self.delegate foldView:pagerView mainTableViewDidScroll:scrollView];
}

- (void)pagerView:(BDXPagerView *)pagerView listScrollViewDidScroll:(UIScrollView *)scrollView {
    [self.delegate foldView:pagerView listScrollViewDidScroll:scrollView];
}

#pragma mark - BDXPagerMainTableViewGestureDelegate

- (BOOL)mainTableViewGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // In some cases, list will be loaded after foldview create,and we can't detect that the list has been added on
    // find list in validListDict only
    NSInteger currentIndex = self.foldView.listContainerView.currentIndex;
    id<BDXPagerViewListViewDelegate> listDelegate = [self.foldView.validListDict objectForKey:@(currentIndex)];
    UIView *currentScrollingList = [listDelegate listScrollView];
    // Only when gesture works on current list it self(and not his sub list),
    // two gesture should work together,otherwise should works on other list view
    // so they won't be conflicted
    return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]
            && ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]
            && otherGestureRecognizer.view == currentScrollingList);
}

#pragma mark - BDXLynxRefreshViewConfigInject

- (void)refreshViewInjection:(BDXLynxRefreshViewInjectBlock)injection {
    self.refreshViewInjectBlock = injection;
    if (self.foldView) {
        self.refreshViewInjectBlock(self.foldView.mainTableView);
    }
}


@end


@interface BDXLynxFoldViewPro () <BDXFoldViewProDelegate, BDXLynxFoldHeaderViewProDelegate, BDXLynxPageViewProDelegate>

@property(nonatomic, strong, nonnull) NSMutableArray<LynxUI *> *foldItems;
@property (nonatomic, assign) BOOL hasDataChanged;
@property (nonatomic, strong) BDXLynxPageViewPro *lynxPage;
 
@property (nonatomic, assign) BOOL hasReported;

@property (nonatomic, assign) BOOL allowVerticalBounce;
// Notify the granularity of the front-end offset, such as 0.01, initialized to 2.0 does not consider the granularity
@property (nonatomic, assign) CGFloat granularity;
// Save the header offset percent of the previous notification
@property (nonatomic, assign) CGFloat preHeaderOffsetPercent;

@property (nonatomic, assign) BOOL    scrollBarEnable;
@property (nonatomic, assign) BOOL    pageRefresh;
@property (nonatomic, assign) BOOL    scrollEnable;
@property (nonatomic, assign) int gestureDirection;


@end

@implementation BDXLynxFoldViewPro

- (instancetype)init {
    self = [super init];
    if (self) {
        _foldItems = [[NSMutableArray alloc] init];
        _granularity = 2.0;
        _preHeaderOffsetPercent = 0.0;
        _scrollBarEnable = YES;
        _scrollEnable = YES;
    }
    return self;
}

- (UIView *)createView {
    BDXFoldViewPro *view = [[BDXFoldViewPro alloc] init];
    view.delegate = self;
    return view;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
    [_foldItems insertObject:child atIndex:index];
    _hasDataChanged = YES;
    if ([child isKindOfClass:[BDXLynxFoldHeaderViewPro class]]) {
        BDXLynxFoldHeaderViewPro *lynxHeader = (BDXLynxFoldHeaderViewPro *)child;
        lynxHeader.delegate = self;
        self.view.headerView = lynxHeader.view;
    } else if ([child isKindOfClass:[BDXLynxPageViewPro class]]) {
        self.lynxPage = (BDXLynxPageViewPro *)child;
        self.lynxPage.tagDelegate = self;
        self.view.pageView = self.lynxPage.view;
    } else if ([child isKindOfClass:[BDXLynxFoldViewBarPro class]]) {
        self.view.barView = ((BDXLynxFoldViewBarPro *)child).view;
    }
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    [_foldItems removeObjectAtIndex:index];
    _hasDataChanged = YES;
    if ([child isKindOfClass:[BDXLynxFoldHeaderViewPro class]]) {
        self.view.headerView = nil;
    } else if ([child isKindOfClass:[BDXLynxPageViewPro class]]) {
        self.lynxPage = nil;
        self.view.pageView = nil;
    } else if ([child isKindOfClass:[BDXLynxFoldViewBarPro class]]) {
        self.view.barView = nil;
    }
}

- (void)layoutDidFinished {
    if(self.view.barView != nil){
        self.view.pinSectionHeaderOffset = self.view.barView.frame.size.height;
    } else {
        self.view.pinSectionHeaderOffset = 0;
    }
    if (_hasDataChanged && self.view.pageView) {
        _hasDataChanged = NO;
        [self.view setupFoldView:_pageRefresh
                 scrollBarEnable:_scrollBarEnable
             allowVerticalBounce:_allowVerticalBounce
                           isRTL:self.isRtl];
        self.view.foldView.verticalScrollEnabled = _scrollEnable;
      [self.view.foldView.listContainerView setGestureDirection:self.gestureDirection];
    }
}

#pragma mark - BDXFoldViewProDelegate

- (id<BDXPagerViewListViewDelegate>)foldView:(BDXPagerView *)pagerView initListAtIndex:(NSInteger)index {
    BDXLynxPageViewItemPro *i = [self.lynxPage.pageItems objectAtIndex:index];
    return i.view;
}

- (void)foldView:(BDXPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView {
    [self mainTableViewOffset:scrollView.contentOffset];
}

- (void)foldView:(BDXPagerView *)pagerView listScrollViewDidScroll:(UIScrollView *)scrollView {
    NSString *index = [NSString stringWithFormat:@"%.2f",scrollView.contentOffset.x/scrollView.frame.size.width];
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"offsetchange" targetSign:[self.lynxPage sign] detail:@{@"offset":index}];
    [self.lynxPage.context.eventEmitter sendCustomEvent:event];
}

- (NSUInteger)foldViewHeaderViewHeight {
    NSUInteger header = (NSUInteger)self.view.headerView.frame.size.height;
    return header;
}

#pragma mark - BDXLynxFoldHeaderViewProDelegate

- (void)lynxFoldHeaderLayoutIfNeeded:(BDXLynxFoldHeaderViewPro *)lynxFoldHeader {
    if (self.view.pageView) {
        [self.view.foldView reloadData];
    }
}

#pragma mark - BDXLynxPageViewProDelegate

- (void)lynxPageViewLayoutIfNeeded {
    if (self.view.pageView) {
        [self.view.foldView reloadData];
    }
}

#pragma mark - Private
//
- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    LynxUI* guard = nil;
    guard = [self hitTest:point withEvent:event onUIWithCustomLayout:self];
    point = [self.view convertPoint:point toView:guard.view];
    if (guard == nil) {
      // no new result
      return self;
    }
    return [guard hitTest:point withEvent:event];
}

- (LynxUI*)hitTest:(CGPoint)point withEvent:(UIEvent*)event onUIWithCustomLayout:(LynxUI*)ui {
    UIView* view = [ui.view hitTest:point withEvent:event];
    if (view == ui.view || !view) {
        return nil;
    }
    
    UIView* targetViewWithUI = view;
    while (view.superview != ui.view) {
        view = view.superview;
        if (view.lynxSign) {
            targetViewWithUI = view;
        }
    }
    if ([targetViewWithUI isKindOfClass:BDXPageItemViewPro.class]) {
        for (LynxUI* child in self.lynxPage.children) {
            if (child.view == targetViewWithUI) {
                return child;
            }
        }
    }
    for (LynxUI* child in ui.children) {
        if (child.view == targetViewWithUI) {
            return child;
        }
    }
    return nil;
}

//- (void)didSelectPage:(LynxUI *)page {
//    [[self view].oleScrollView updateTabBarView: self.pageView.view];
//
//    CGFloat barHeight = self.barView.view == nil? 0: self.barView.view.frame.size.height;
//    CGFloat headerHeight = self.headerView.view.frame.size.height;
//    CGFloat deltaHeight = headerHeight - barHeight;
//    if([self view].oleScrollView.contentOffset.y < 0) {
//        [self setFoldExpanded:YES];
//    } else if ([self view].oleScrollView.contentOffset.y > deltaHeight) {
//        [self setFoldExpanded:NO];
//    } else {
//
//    }
//}

- (void)mainTableViewOffset:(CGPoint)offset {
    CGFloat barHeight = self.view.barView == nil? 0: self.view.barView.frame.size.height;
    CGFloat headerHeight = self.view.headerView.frame.size.height;
    CGFloat deltaHeight = headerHeight - barHeight;
    if(deltaHeight <= 0) return;
    CGFloat percent = offset.y / deltaHeight;
    if(percent < 1) { _hasReported = NO; }
    if(percent >= 1) { percent = 1; }
    if(!_hasReported){
        [self.context.eventEmitter notifyIntersectionObserver];
        if(_granularity > 1){
            // No control granularity on the front end
            [self headerOffsetting:@{@"offset":@(percent)}];
        }else{
            if(_preHeaderOffsetPercent<percent){
                // Current decline
                while(true){
                    _preHeaderOffsetPercent += _granularity;
                    if(_preHeaderOffsetPercent>=percent){
                        [self headerOffsetting:@{@"offset":@(percent)}];
                        break;
                    }else{
                        [self headerOffsetting:@{@"offset":@(_preHeaderOffsetPercent)}];
                    }
                }
            }else{
                // Currently sliding up
                while(true){
                    _preHeaderOffsetPercent -= _granularity;
                    if(_preHeaderOffsetPercent<=percent){
                        [self headerOffsetting:@{@"offset":@(percent)}];
                        break;
                    }else{
                        [self headerOffsetting:@{@"offset":@(_preHeaderOffsetPercent)}];
                    }
                }
            }
        }
        if(percent >= 1) { _hasReported = YES; }
    }
    _preHeaderOffsetPercent = percent;
}

- (void)headerOffsetting:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"offset" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-pro")
#else
LYNX_REGISTER_UI("x-foldview-pro")
#endif

//TODO:AKing 验证效果
LYNX_UI_METHOD(setFoldExpanded) {
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"expanded"]) {
        CGFloat expanded = [[params objectForKey:@"expanded"] floatValue];
        BOOL animate = [[params objectForKey:@"enableAnimation"] boolValue];
        if(expanded < 0) expanded = 0;
        if(expanded > 1) expanded = 1;
        CGFloat barHeight = self.view.barView == nil? 0: self.view.barView.frame.size.height;
        CGFloat headerHeight = self.view.headerView.frame.size.height;
        CGFloat deltaHeight = headerHeight - barHeight;
        if([self view].foldView.mainTableView.contentOffset.y > deltaHeight){
            success = NO;
            msg = @"header must be folded";
        }else{
            [[self view].foldView.mainTableView setContentOffset:CGPointMake(0, deltaHeight * (1.0 - expanded))
                                                        animated:animate];
            success = YES;
            msg = @"";
        }
    } else {
        success = NO;
        msg = @"no expanded key";
    }
    callback(
      kUIMethodSuccess, @{
          @"success": @(success),
          @"msg": msg,
      });
}

-(void)setFoldExpanded :(BOOL)expanded {
    if(expanded){
        self.view.foldView.mainTableView.contentOffset = CGPointMake(0, 0);
    } else {
        CGFloat barHeight = self.view.barView == nil? 0: self.view.barView.frame.size.height;
        CGFloat headerHeight = self.view.headerView.frame.size.height;
        CGFloat deltaHeight = headerHeight - barHeight;
        [self view].foldView.mainTableView.contentOffset = CGPointMake(0, deltaHeight);
    }
}

LYNX_PROP_SETTER("allow-vertical-bounce", allowVerticalBounce, BOOL) {
    _allowVerticalBounce = value;
}

LYNX_PROP_SETTER("granularity", granularity, CGFloat) {
    _granularity = value;
}

LYNX_PROP_SETTER("scroll-bar-enable",  scrollBarEnable , BOOL) {
    _scrollBarEnable = value;
}

LYNX_PROP_SETTER("refresh-mode", refreshMode, NSString *) {
    FoldViewRefreshMode mode = FoldViewRefreshModeNone;
    if([value isEqual: @"fold"]) mode = FoldViewRefreshModeFold;
    else if([value isEqual: @"page"]) mode = FoldViewRefreshModePage;
    _pageRefresh = mode == FoldViewRefreshModePage;
}

LYNX_PROP_SETTER("scroll-enable",  scrollEnable , BOOL) {
    _scrollEnable = value;
    self.view.foldView.verticalScrollEnabled = _scrollEnable;
}

LYNX_PROP_SETTER("ios-gesture-direction", gestureDirection, int) {
    self.gestureDirection = value;
}

@end
