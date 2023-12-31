//
//  UIScrollView+TMARefresh.m
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//
#import "UIScrollView+TMARefresh.h"
#import <objc/runtime.h>

#define BottomInsetNotSet -1

static char TMAPullRefreshViewDown, TMAPullRefreshViewNeedPullRefresh;

@implementation UIScrollView (TMARefresh)

@dynamic tmaRefreshView;

- (void)addPullDownWithActionHandler:(dispatch_block_t)actionHandler
{
    if (!self.tmaRefreshView) {
        CGRect frame = CGRectMake(0, self.tmaRefreshViewTopInset-kTMAPullRefreshHeight, self.bounds.size.width, kTMAPullRefreshHeight);
        TMARefreshView *view = [[TMARefreshView alloc] initWithFrame:frame];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self insertSubview:view atIndex:0];

        self.tmaRefreshView = view;
        self.tmaRefreshView.actionHandler = actionHandler;
        self.tmaRefreshView.scrollView = self;
        [self.tmaRefreshView startObserve];
    }
    self.tmaRefreshView.actionHandler = actionHandler;
    self.tmaRefreshView.accessibilityElementsHidden = YES;
}

- (void)tmaTriggerPullDownAndHideAnimationView {
    if (self.tmaRefreshView && self.tmaRefreshView.state != TMAPULL_REFRESH_STATE_LOADING) {
        [self.tmaRefreshView triggerRefreshAndHideAnimationView];
    }
}

- (void)tmaTriggerPullDown
{
    if (self.tmaRefreshView && self.tmaRefreshView.state != TMAPULL_REFRESH_STATE_LOADING) {
        [self.tmaRefreshView triggerRefresh];
    }
}

- (void)tmaFinishPullDownWithSuccess:(BOOL)success
{
    [self.tmaRefreshView stopAnimation:success];
}

- (void)tmaPullView:(UIView *)view stateChange:(TMAPullState)state
{

}

- (TMARefreshView *)tmaRefreshView
{
    return objc_getAssociatedObject(self, &TMAPullRefreshViewDown);
}

- (void)setTmaRefreshView:(TMARefreshView *)tmaRefreshView
{
    [self willChangeValueForKey:@"TMAPullRefreshViewDown"];
    objc_setAssociatedObject(self, &TMAPullRefreshViewDown, tmaRefreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"TMAPullRefreshViewDown"];
}

- (BOOL)needPullRefresh {
    NSNumber *number = objc_getAssociatedObject(self, &TMAPullRefreshViewNeedPullRefresh);
    if (![number boolValue]) {
        return YES;
    }
    return [number boolValue];
}

- (void)setNeedPullRefresh:(BOOL)needPullRefresh {
    objc_setAssociatedObject(self, &TMAPullRefreshViewNeedPullRefresh, @(needPullRefresh), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.tmaRefreshView.enabled = needPullRefresh;
}

- (BOOL)isDone
{
    NSNumber *number = objc_getAssociatedObject(self, @selector(isDone));
    return [number boolValue];
}

- (void)setIsDone:(BOOL)isDone
{
    NSNumber *number = [NSNumber numberWithBool:isDone];
    objc_setAssociatedObject(self,@selector(isDone), number, OBJC_ASSOCIATION_RETAIN);
}

- (UIEdgeInsets)originContentInset
{
    NSValue * value = objc_getAssociatedObject(self, @selector(originContentInset));
    return [value UIEdgeInsetsValue];
}

- (void)setOriginContentInset:(UIEdgeInsets)originContentInset
{
    NSValue *value = [NSValue valueWithUIEdgeInsets:originContentInset];
    objc_setAssociatedObject(self, @selector(originContentInset), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)customTopOffset
{
    NSNumber * num = objc_getAssociatedObject(self, @selector(customTopOffset));
    return (CGFloat)[num floatValue];
}

- (void)setCustomTopOffset:(CGFloat)customTopOffset
{
    NSNumber *value = [NSNumber numberWithFloat:customTopOffset];
    objc_setAssociatedObject(self, @selector(customTopOffset), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)tmaRefreshViewTopInset
{
    NSNumber * num = objc_getAssociatedObject(self, @selector(tmaRefreshViewTopInset));
    return (CGFloat)[num floatValue];
}

- (void)setTmaRefreshViewTopInset:(CGFloat)tmaRefreshViewTopInset
{
    NSNumber *value = [NSNumber numberWithFloat:tmaRefreshViewTopInset];
    objc_setAssociatedObject(self, @selector(tmaRefreshViewTopInset), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end

