//
//  ACCSlidingViewController.m
//  CameraClient
//
//  Created by gongyanyun  on 2018/6/22.
//

#import "ACCSlidingViewController.h"

@interface UIScrollView (ACCSlidingScroll)

- (NSInteger)acc_currentPageIndex;

@end

@implementation UIScrollView (ACCSlidingScroll)

- (NSInteger)acc_currentPageIndex
{
    return (NSInteger)round(self.contentOffset.x / self.bounds.size.width);
}

@end

@interface ACCSlidingViewController ()

@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, assign) NSInteger animatingDestinationIndex;
@property (nonatomic, assign) BOOL isViewAppearing;
@property (nonatomic, assign) NSInteger scrollPreIndex; // When fast sliding, record the previous index
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, strong) NSMutableArray<UIViewController *> *transitionAppearArray;
@property (nonatomic, strong) NSMutableArray<UIViewController *> *transitionDisappearArray;
@property (nonatomic, strong) NSMutableArray<UIViewController *> *appearCompleteArray;
@property (nonatomic, assign) BOOL isScrollingWhileDisappear;

@end

@implementation ACCSlidingViewController

- (instancetype)init
{
    return [self initWithSelectedIndex:-1];
}

- (instancetype)initWithSelectedIndex:(NSInteger)index
{
    self = [super init];
    if (self) {
        _viewControllers = [NSMutableArray array];
        _slideEnabled = YES;
        _isScrolling = NO;
        _needAnimationWithTapTab = NO;
        _selectedIndex = index;
        _animatingDestinationIndex = -1;
        _scrollPreIndex = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupContentView];
    [self scrollToIndex:self.selectedIndex animated:NO];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isViewAppearing = YES;
    [[self currentVCAtIndex:self.selectedIndex] beginAppearanceTransition:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isViewAppearing = YES;
    UIViewController *vc = [self currentVCAtIndex:self.selectedIndex];
    [vc endAppearanceTransition];
    [self vcHasCompleteAppear:vc];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.isScrolling) {
        self.isScrollingWhileDisappear = NO;
        [[self currentVCAtIndex:self.selectedIndex] beginAppearanceTransition:NO animated:YES];
    } else {
        self.isScrollingWhileDisappear = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isViewAppearing = NO;
    [self correctSelectedIndexIfNeededWithScrollView:self.contentScrollView];
    if (!self.isScrollingWhileDisappear) {
        UIViewController *vc = [self currentVCAtIndex:self.selectedIndex];
        [vc endAppearanceTransition];
        [self vcHasCompleteDisappear:vc];
    }
    [self _makeControllersDidAppear];
    for (UIViewController *vc in self.appearCompleteArray) {
        [vc beginAppearanceTransition:NO animated:YES];
        [vc endAppearanceTransition];
    }
    [self.appearCompleteArray removeAllObjects];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.contentScrollView.frame = self.view.bounds;
    for (NSInteger index = 0; index < self.viewControllers.count; index ++) {
        id obj = self.viewControllers[index];
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *viewController = (UIViewController *)obj;
            viewController.view.frame = CGRectMake(index * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        }
    }
}

#pragma mark - subview

- (void)setupContentView
{
    self.contentScrollView = [[[self scrollViewClass] alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.contentScrollView.scrollEnabled = self.slideEnabled;
    self.contentScrollView.pagingEnabled = YES;
    self.contentScrollView.showsVerticalScrollIndicator = NO;
    self.contentScrollView.showsHorizontalScrollIndicator = NO;
    self.contentScrollView.delegate = self;
    self.contentScrollView.bounces = NO;
    [self.view addSubview:self.contentScrollView];
    [self reloadViewControllers];
}

#pragma mark - Setters

- (void)setShouldAdjustScrollInsets:(BOOL)shouldAdjustScrollInsets
{
    _shouldAdjustScrollInsets = shouldAdjustScrollInsets;
    if (!shouldAdjustScrollInsets) {
        if (@available(iOS 11.0, *)) {
            self.contentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    } else {
        if (@available(iOS 11.0, *)) {
            self.contentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        }
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (!self.isScrolling) {
        [self scrollToIndex:selectedIndex animated:(self.needAnimationWithTapTab && self.slideEnabled)];
    }
}

- (void)setSlideEnabled:(BOOL)slideEnabled
{
    _slideEnabled = slideEnabled;
    self.contentScrollView.scrollEnabled = slideEnabled;
}

- (void)setTabbarView:(UIView<ACCSlidingTabbarProtocol> *)tabbarView
{
    _tabbarView = tabbarView;
    tabbarView.slidingViewController = self;
}

#pragma mark - Getters

- (NSMutableArray *)viewControllers
{
    if (!_viewControllers) {
        _viewControllers = [NSMutableArray array];
    }
    return _viewControllers;
}

#pragma mark - public

- (UIViewController *)controllerAtIndex:(NSInteger)index
{
    UIViewController *controller = nil;
    if (index < self.viewControllers.count && index >= 0) {
        id object = self.viewControllers[index];
        if (object == [NSNull null]) {
            if ([self.delegate respondsToSelector:@selector(slidingViewController:viewControllerAtIndex:)]) {
                controller = [self.delegate slidingViewController:self viewControllerAtIndex:index];
            }
        } else {
            controller = (UIViewController *)object;
        }
    }
    return controller;
}

- (void)reloadViewControllers
{
    NSInteger count = [self numberOfControllers];
    for (UIViewController *childController in self.childViewControllers) {
        [childController willMoveToParentViewController:nil];
        [childController removeFromParentViewController];
    }
    for (UIView  *subView in self.contentScrollView.subviews) {
        [subView removeFromSuperview];
    }
    [self.viewControllers removeAllObjects];

    for (NSInteger i = 0; i < count; i++) {
        [self.viewControllers addObject:[NSNull null]];
    }
    self.contentScrollView.contentSize = CGSizeMake(self.view.bounds.size.width * count, 0);
    
    if (self.selectedIndex >= count) {
        self.selectedIndex = count - 1;
    }
}

- (NSInteger)numberOfControllers
{
    NSInteger count = 0;
    if ([self.delegate respondsToSelector:@selector(numberOfControllers:)]) {
        count = [self.delegate numberOfControllers:self];
    }
    return count;
}

- (NSArray *)currentViewControllers
{
    return [self.viewControllers copy];
}

#pragma mark - private

- (void)useSwipeCardEffect
{
    CGPoint originOffset = CGPointMake(self.selectedIndex * self.view.bounds.size.width, self.view.bounds.origin.y);
    CGFloat ratio = fabs(self.contentScrollView.contentOffset.x - originOffset.x) / self.contentScrollView.bounds.size.width;
    CGFloat minimumRatio = 0.94f;
    CGFloat ratioToScaleSmaller = 1 - (1 - minimumRatio) * ratio;
    CGFloat ratioToScaleBigger = 1 - (1 - minimumRatio) * (1 - ratio);
    
    UIViewController *currentVC = [self controllerAtIndex:self.selectedIndex];
    if (currentVC) {
        currentVC.view.transform = CGAffineTransformMakeScale(ratioToScaleSmaller, ratioToScaleSmaller);
    }
    
    if (self.contentScrollView.contentOffset.x > originOffset.x) {
        UIViewController *vc = [self controllerAtIndex:self.selectedIndex + 1];
        if (vc) {
            vc.view.transform = CGAffineTransformMakeScale(ratioToScaleBigger, ratioToScaleBigger);
        }
    } else if (self.contentScrollView.contentOffset.x < originOffset.x) {
        UIViewController *vc = [self controllerAtIndex:self.selectedIndex - 1];
        if (vc) {
            vc.view.transform = CGAffineTransformMakeScale(ratioToScaleBigger, ratioToScaleBigger);
        }
    }
}

- (void)updateSelectedIndexWithScrollView:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    if (index < 0 || index >= [self numberOfControllers]) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didFinishTransitionToIndex:)]) {
        [self.delegate slidingViewController:self didFinishTransitionToIndex:index];
    }
    
    if (self.animatingDestinationIndex != index && index == self.selectedIndex) {
        UIViewController *newVC = [self controllerAtIndex:self.animatingDestinationIndex];
        [newVC beginAppearanceTransition:NO animated:YES];
        [newVC endAppearanceTransition];
        [self vcHasCompleteDisappear:newVC];
        [self.transitionAppearArray removeObject:newVC];
        [self.transitionDisappearArray removeObject:newVC];
        UIViewController *oldVC = [self controllerAtIndex:self.selectedIndex];
        [oldVC beginAppearanceTransition:YES animated:YES];
        [oldVC endAppearanceTransition];
        [self vcHasCompleteAppear:oldVC];
        [self.transitionAppearArray removeObject:oldVC];
        [self.transitionDisappearArray removeObject:oldVC];
        [self _makeControllersDidAppear];
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didFinishTransitionFromPreviousViewController:currentViewController:)]) {
            [self.delegate slidingViewController:self didFinishTransitionFromPreviousViewController:[self currentVCAtIndex:self.selectedIndex] currentViewController:[self currentVCAtIndex:self.selectedIndex]];
        }
    }
    
    if (index == self.selectedIndex) {
        return;
    }
    
    [self updateScrollIndexControllerWithTransitionType:ACCSlidingVCTransitionTypeScroll index:index];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated
{
    NSInteger count = [self numberOfControllers];
    if (index < 0 || index >= count) {
        return;
    }
    CGFloat targetOffset = self.contentScrollView.bounds.size.width * index;
    [self updateScrollIndexControllerWithTransitionType:ACCSlidingVCTransitionTypeTapTab index:index];
    [self.contentScrollView setContentOffset:CGPointMake(targetOffset, self.contentScrollView.contentOffset.y) animated:animated];
    if (self.tabbarView && [self.tabbarView respondsToSelector:@selector(updateSelectedLineFrame)]) {
        [self.tabbarView updateSelectedLineFrame];
    }
}

- (void)updateScrollIndexControllerWithTransitionType:(ACCSlidingVCTransitionType)transitionType index:(NSInteger)index
{
    [self _makeViewControllerVisibleAtIndex:index transitionType:transitionType];
    
    UIViewController *controller = [self controllerAtIndex:self.selectedIndex];
    if (controller) {
        if (self.enableSwipeCardEffect) {
            controller.view.transform = CGAffineTransformIdentity;
        }

        controller.view.frame = CGRectMake(self.selectedIndex * self.contentScrollView.bounds.size.width, 0, self.contentScrollView.bounds.size.width, self.view.bounds.size.height);
    }
    
    
    if (self.tabbarView) {
        if ([self.tabbarView respondsToSelector:@selector(setSelectedIndex:animated:tapped:)]) {
            BOOL tapped = (transitionType == ACCSlidingVCTransitionTypeTapTab);
            [self.tabbarView setSelectedIndex:self.selectedIndex animated:YES tapped:tapped];
        } else if ([self.tabbarView respondsToSelector:@selector(setSelectedIndex:)]) {
            [self.tabbarView setSelectedIndex:self.selectedIndex];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didSelectIndex:)]) {
        [self.delegate slidingViewController:self didSelectIndex:self.selectedIndex];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didSelectIndex:transitionType:)]) {
        [self.delegate slidingViewController:self didSelectIndex:self.selectedIndex transitionType:transitionType];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didFinishTransitionToIndex:)]) {
        [self.delegate slidingViewController:self didFinishTransitionToIndex:index];
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tabbarView && [self.tabbarView respondsToSelector:@selector(slidingControllerDidScroll:)]) {
        [self.tabbarView slidingControllerDidScroll:scrollView];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewControllerDidScroll:)]) {
        [self.delegate slidingViewControllerDidScroll:scrollView];
    }
    
    if (self.enableSwipeCardEffect) {
        [self useSwipeCardEffect];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isScrolling = YES;
    CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:scrollView.superview];
    NSInteger nextIndex = [scrollView acc_currentPageIndex];
    if (velocity.x < 0) {
        nextIndex++;
    } else {
        nextIndex--;
    }
    if (nextIndex >= 0 && nextIndex < self.viewControllers.count) {
        NSInteger curIndex = [scrollView acc_currentPageIndex];
        self.scrollPreIndex = self.animatingDestinationIndex;
        [self _makeControllersWillAppearAtPreIndex:curIndex currentIndex:nextIndex];
        self.animatingDestinationIndex = nextIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willTransitionToViewController:)]) {
            [self.delegate slidingViewController:self willTransitionToViewController:[self currentVCAtIndex:nextIndex]];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willTransitionToViewController:transitionType:)]) {
            [self.delegate slidingViewController:self willTransitionToViewController:[self currentVCAtIndex:nextIndex] transitionType:ACCSlidingVCTransitionTypeScroll];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.isScrolling = NO;
    [self updateSelectedIndexWithScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.isScrolling = NO;
        [self updateSelectedIndexWithScrollView:scrollView];
    }
}

#pragma mark - child VC life cycle

- (void)_makeViewControllerVisibleAtIndex:(NSInteger)index transitionType:(ACCSlidingVCTransitionType)transitionType
{
    if (index >= self.viewControllers.count || index < 0) {
        return;
    }
    if (transitionType == ACCSlidingVCTransitionTypeScroll) {
        UIViewController *controller = [self controllerAtIndex:index];
        NSInteger fromIndex = self.scrollPreIndex != -1 ? self.scrollPreIndex : self.selectedIndex;
        if (labs(fromIndex - index) > 1) {
            for (UIViewController *vc in self.transitionAppearArray) {
                NSInteger vcIndex = [self.childViewControllers indexOfObject:vc];
                if (![self.transitionDisappearArray containsObject:vc] && vc != controller && labs(vcIndex - index) == 1) {
                    fromIndex = vcIndex;
                    break;
                }
            }
        }
                
        if (![self.childViewControllers containsObject:controller] && controller) {
            [self _makeControllersWillAppearAtPreIndex:fromIndex currentIndex:index];
        }
        [self _makeControllersDidAppear];
    } else {
        [self _makeControllersWillAppearAtPreIndex:self.selectedIndex currentIndex:index];
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willTransitionToViewController:)]) {
            [self.delegate slidingViewController:self willTransitionToViewController:[self currentVCAtIndex:index]];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willTransitionToViewController:transitionType:)]) {
            [self.delegate slidingViewController:self willTransitionToViewController:[self currentVCAtIndex:index] transitionType:ACCSlidingVCTransitionTypeTapTab];
        }
        [self _makeControllersDidAppear];
    }
    
    NSInteger previousSelectedIndex = self.selectedIndex;
    _selectedIndex = index;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didFinishTransitionFromPreviousViewController:currentViewController:)]) {
        [self.delegate slidingViewController:self didFinishTransitionFromPreviousViewController:[self currentVCAtIndex:previousSelectedIndex] currentViewController:[self currentVCAtIndex:_selectedIndex]];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didFinishTransitionFromPreviousIndex:currentIndex:transitionType:)]) {
        [self.delegate slidingViewController:self didFinishTransitionFromPreviousIndex:previousSelectedIndex currentIndex:_selectedIndex transitionType:transitionType];
    }
}

- (void)_makeControllersWillAppearAtPreIndex:(NSInteger)preIdx currentIndex:(NSInteger)currentIdx
{
    UIViewController *controller = [self controllerAtIndex:currentIdx];
    if (![self.childViewControllers containsObject:controller] && controller) {
        [self addViewController:controller atIndex:currentIdx];
    }

    if (preIdx != currentIdx) {
        UIViewController *oldVC = [self currentVCAtIndex:preIdx];
        if (oldVC && [self.childViewControllers containsObject:oldVC]) {
            [oldVC beginAppearanceTransition:NO animated:YES];
            if ([self.transitionDisappearArray containsObject:oldVC]) {
                [self.transitionDisappearArray removeObject:oldVC];
            }
            [self.transitionDisappearArray addObject:oldVC];
        }
    }
    UIViewController *newVC = [self currentVCAtIndex:currentIdx];
    if (newVC && self.isViewAppearing) {
        [newVC beginAppearanceTransition:YES animated:YES];
        if ([self.transitionAppearArray containsObject:newVC]) {
            [self.transitionAppearArray removeObject:newVC];
        }
        [self.transitionAppearArray addObject:newVC];
    }
}

- (void)_makeControllersDidAppear
{
    for (UIViewController *vc in self.transitionDisappearArray) {
        [vc endAppearanceTransition];
        [self vcHasCompleteDisappear:vc];
    }
    for (UIViewController *vc in self.transitionAppearArray) {
        [vc endAppearanceTransition];
        [self vcHasCompleteAppear:vc];
    }
    
    [self.transitionDisappearArray removeAllObjects];
    [self.transitionAppearArray removeAllObjects];
}

- (void)vcHasCompleteAppear:(UIViewController *)controller
{
    if ([self.appearCompleteArray containsObject:controller]) {
        [self.appearCompleteArray removeObject:controller];
    }
    if (controller) {
        [self.appearCompleteArray addObject:controller];
    }
}

- (void)vcHasCompleteDisappear:(UIViewController *)controller
{
    [self.appearCompleteArray removeObject:controller];
}

- (void)addViewController:(UIViewController *)controller atIndex:(NSInteger)index
{
    if (controller) {
        [self.viewControllers replaceObjectAtIndex:index withObject:controller];
        [self addChildViewController:controller];
        controller.view.frame = CGRectMake(index * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [controller didMoveToParentViewController:self];
        [self.contentScrollView addSubview:controller.view];
    }
}

- (UIViewController *)currentVCAtIndex:(NSInteger)index
{
    UIViewController *controller = nil;
    if (index < self.viewControllers.count && index >= 0) {
        id object = self.viewControllers[index];
        if ([object isKindOfClass:[UIViewController class]]) {
            controller = (UIViewController *)object;
        }
    }
    return controller;
}

- (void)insertAtFrontWithViewController:(UIViewController *)viewController
{
    if (viewController) {
        [self.viewControllers insertObject:viewController atIndex:0];
        [self addChildViewController:viewController];
        viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [viewController didMoveToParentViewController:self];
        [self.contentScrollView addSubview:viewController.view];
        self.contentScrollView.contentSize = CGSizeMake(self.viewControllers.count * self.view.bounds.size.width, 0);
    }
}

- (void)replaceViewController:(UIViewController *)newVC atIndex:(NSInteger)index
{
    if (index < 0 || index >= self.viewControllers.count || !newVC) {
        return;
    }
    UIViewController *vc = self.viewControllers[index];
    [vc removeFromParentViewController];
    [vc didMoveToParentViewController:nil];
    [vc.view removeFromSuperview];
    self.viewControllers[index] = newVC;
    [self addChildViewController:newVC];
    newVC.view.frame = CGRectMake(index * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [newVC didMoveToParentViewController:self];
    [self.contentScrollView addSubview:newVC.view];
}

- (void)appendViewController:(UIViewController *)viewController
{
    if (viewController) {
        [self.viewControllers addObject:viewController];
        [self addChildViewController:viewController];
        viewController.view.frame = CGRectMake((self.viewControllers.count - 1) * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [viewController didMoveToParentViewController:self];
        [self.contentScrollView addSubview:viewController.view];
        self.contentScrollView.contentSize = CGSizeMake(self.viewControllers.count * self.view.bounds.size.width, 0);
    }
}

- (Class)scrollViewClass
{
    return [ACCSlidingScrollView class];
}

- (NSInteger)currentScrollPage
{
    return self.contentScrollView.acc_currentPageIndex;
}

- (NSMutableArray<UIViewController *> *)transitionAppearArray
{
    if (!_transitionAppearArray) {
        _transitionAppearArray = [NSMutableArray array];
    }
    return _transitionAppearArray;
}
- (NSMutableArray<UIViewController *> *)transitionDisappearArray
{
    if (!_transitionDisappearArray) {
        _transitionDisappearArray = [NSMutableArray array];
    }
    return _transitionDisappearArray;
}

- (NSMutableArray<UIViewController *> *)appearCompleteArray
{
    if (!_appearCompleteArray) {
        _appearCompleteArray = [NSMutableArray array];
    }
    return _appearCompleteArray;
}

#pragma mark - helpers

- (NSArray<UIView *> *)visibleViews
{
    CGRect visibleRect = CGRectMake(self.contentScrollView.contentOffset.x, 0, self.contentScrollView.bounds.size.width, self.contentScrollView.bounds.size.height);
    NSMutableArray *views = [NSMutableArray array];
    for (NSInteger i = 0; i < [self numberOfControllers]; i++) {
        UIViewController *VC = [self controllerAtIndex:i];
        CGRect frame = CGRectMake(i * self.contentScrollView.bounds.size.width, 0, self.contentScrollView.bounds.size.width, self.contentScrollView.bounds.size.height);
        if (CGRectIntersectsRect(frame, visibleRect)) {
            [views addObject:VC.view];
        }
    }
    return views;
}

- (void)enumerateChildViewControllers:(UIViewController *)currentVC usingBlock:(void (^)(UIViewController *childVC))block
{
    if (!currentVC) {
        return;
    }
    if (currentVC.childViewControllers.count <= 0) {
        if (block) {
            block(currentVC);
        }
        return;
    }
    NSMutableArray<UIViewController *> *containerArray = [NSMutableArray arrayWithObject:currentVC];
    while (containerArray.count > 0) {
        UIViewController *vc = containerArray[0];
        if (block) {
            block(vc);
        }
        [containerArray removeObjectAtIndex:0];
        if (vc) {
            if (vc.childViewControllers.count > 0) {
                [containerArray addObjectsFromArray:vc.childViewControllers];
            }
        }
    }
}

- (void)correctSelectedIndexIfNeededWithScrollView:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    if (index < 0 || index >= [self numberOfControllers]) {
        return;
    }
    
    if (index == self.selectedIndex) {
        return;
    }
    
    [self updateScrollIndexControllerWithTransitionType:ACCSlidingVCTransitionTypeScroll index:index];
}

@end
