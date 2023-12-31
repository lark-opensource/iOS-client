//
//  TMARefreshView.m
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//

#import "TMARefreshView.h"
#import <OPFoundation/BDPUtils.h>

#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/NSTimer+BDPWeakTarget.h>
#import "UIScrollView+TMARefresh.h"

@interface TMARefreshView ()

@property (nonatomic, strong) UIView<TMARefreshAnimationDelegate> *refreshAnimateView;
@property (nonatomic, assign) UIEdgeInsets restingContentInset;
@property (nonatomic, assign) CGPoint lastPanPoint;
@property (nonatomic, strong) NSTimer *resetTimer;

@end

@implementation TMARefreshView

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        _state = -1;
        _enabled = YES;

        self.pullRefreshLoadingHeight = kTMAPullRefreshHeight;
        self.secondsNeedScrollToLoading = KTMASecondsNeedScrollToLoading;
        self.state = TMAPULL_REFRESH_STATE_INIT;
    }
    return self;
}

#pragma-- mark 动态设置RefreshAnimateView

//动态设置refreshAnimateView
- (void)reConfigureWithRefreshAnimateView:(UIView<TMARefreshAnimationDelegate> *)refreshAnimateView
           WithConfigureSuccessCompletion:(void (^)(BOOL))completion {

    if (!refreshAnimateView) {
        return;
    }

    if (self.refreshAnimateView && self.refreshAnimateView == refreshAnimateView) {
        return;
    }

    self.refreshAnimateView = refreshAnimateView;
    if (self.refreshAnimateView == refreshAnimateView) {
        if (completion) {
            completion(YES);
            completion = nil;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqual:@"contentInset"]) {

        if (self.state != TMAPULL_REFRESH_STATE_LOADING) {
            if (self.scrollView.originContentInset.bottom == 0) {
                self.scrollView.originContentInset = _scrollView.contentInset;
            } else {
                self.scrollView.originContentInset = UIEdgeInsetsMake(_scrollView.contentInset.top, 0, _scrollView.originContentInset.bottom, 0);
            }
        } else {
            if (self.scrollView.originContentInset.bottom == 0) {
                self.scrollView.originContentInset = UIEdgeInsetsMake(_scrollView.contentInset.top - kTMAPullRefreshHeight, 0, _scrollView.contentInset.bottom, 0);
            } else
                self.scrollView.originContentInset = UIEdgeInsetsMake(_scrollView.contentInset.top - kTMAPullRefreshHeight, 0, _scrollView.originContentInset.bottom, 0);
        }
    }

    if (self.hidden) {
        return;
    }

    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self contentOffsetChange:change];
    }
}

- (void)contentOffsetChange:(NSDictionary *)change {

    if (!self.window || !self.enabled) {
        return;
    }

    CGPoint point = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    
    //触底时结束刷新
    if (point.y + self.scrollView.frame.size.height >= self.scrollView.contentSize.height) {
        [self stopAnimation:YES];
    }

    if (self.state == TMAPULL_REFRESH_STATE_LOADING) {
        return;
    }

    CGFloat offset = point.y;

    // 当前的contentOffset
    CGFloat offsetY = self.scrollView.contentOffset.y;
    // 头部控件刚好出现的offsetY
    CGFloat happenOffsetY = - self.scrollView.originContentInset.top;

    // 如果是向上滚动到看不见头部控件，直接返回
    // >= -> >
    if (offsetY > happenOffsetY) return;

    // 普通 和 即将刷新 的临界点
    CGFloat normal2pullingOffsetY = happenOffsetY - self.pullRefreshLoadingHeight;
    if (self.scrollView.isDragging) { // 如果正在拖拽
        if (self.state == TMAPULL_REFRESH_STATE_INIT && offsetY < normal2pullingOffsetY) {
            // 转为即将刷新状态 mj_offsetY < - self.scrollViewOriginalInset.top - self.mj_h
            self.state = TMAPULL_REFRESH_STATE_PULL;
        } else if (self.state == TMAPULL_REFRESH_STATE_PULL && offsetY >= normal2pullingOffsetY) {
            // 转为普通状态
            self.state = TMAPULL_REFRESH_STATE_INIT;
        }

        // 下拉时更新loading percent
        if (self.state != TMAPULL_REFRESH_STATE_LOADING) {
            if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(updateAnimationWithScrollOffset:)]) {
                [self.refreshAnimateView updateAnimationWithScrollOffset:offset];
            }

            if (self.state == TMAPULL_REFRESH_STATE_INIT) {
                // 停留普通状态一段时间之后，还原scrollView位置
                [self.resetTimer invalidate];
                WeakSelf;
                self.resetTimer = [NSTimer bdp_repeatedTimerWithInterval:0.05 target:self block:^(NSTimer * _Nonnull timer) {
                    StrongSelfIfNilReturn
                    if (!self.scrollView.isTracking && self.state == TMAPULL_REFRESH_STATE_INIT) {
                        [self resetScrollInsets];
                        [self.resetTimer invalidate];
                    }
                }];
                [[NSRunLoop currentRunLoop] addTimer:self.resetTimer forMode:NSRunLoopCommonModes];
            }
        }
    }
    else if (self.state == TMAPULL_REFRESH_STATE_PULL) {// 超过一定距离 即将刷新 && 手松开， 开始刷新
        // 开始刷新
        [self beginRefreshing];
    }
}

- (void)beginRefreshing {
    // 避免重复执行刷新
    if (self.isUserPullAndRefresh) {
        return;
    }
    self.isUserPullAndRefresh = YES;
    self.state = TMAPULL_REFRESH_STATE_LOADING;
    [self setScrollInsets:YES];
}

/// 停止刷新动画时，还原scrollView之前的contentInset和contentOffset状态
- (void)resetScrollInsets {

    if (!self.window) {
        [self setScrollViewContentInsetWithOutObserve:UIEdgeInsetsMake(self.scrollView.originContentInset.top,
                                                                       self.scrollView.originContentInset.left,
                                                                       self.scrollView.originContentInset.bottom,
                                                                       self.scrollView.originContentInset.right)];
        self.scrollView.originContentInset = self.scrollView.contentInset;
        self.state = TMAPULL_REFRESH_STATE_INIT;
        return;
    }

    [UIView animateWithDuration:0.3f animations:^{
        [self setScrollViewContentInsetWithOutObserve:UIEdgeInsetsMake(self.scrollView.originContentInset.top,
                                                                       self.scrollView.originContentInset.left,
                                                                       self.scrollView.originContentInset.bottom,
                                                                       self.scrollView.originContentInset.right)];
        if (self.scrollView.customTopOffset != 0) {
            [UIView performWithoutAnimation:^{
                self.scrollView.contentOffset = CGPointMake(0, self.scrollView.customTopOffset - self.scrollView.contentInset.top);
            }];
        }
    } completion:^(BOOL finished) {
        self.state = TMAPULL_REFRESH_STATE_INIT;
        self.isUserPullAndRefresh = NO;
    }];
}

- (void)doHandler {
    if (_actionHandler) {
        _actionHandler();
    }
}

- (void)stopAnimation:(BOOL)success {
    if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(stopLoading)]) {
        [self.refreshAnimateView stopLoading];
    }

    [self resetScrollInsets];
}

- (void)showAnimationView {
    if (self.refreshAnimateView) {
        self.refreshAnimateView.hidden = NO;
    }
}

- (void)hideAnimationView {
    if (self.refreshAnimateView) {
        self.refreshAnimateView.hidden = YES;
    }
}

- (void)triggerRefreshAndHideAnimationView {
    if (self.hidden) {
        return;
    }
    [self triggerRefresh];
    [self hideAnimationView];
}

- (void)triggerRefresh
{
    if (self.hidden) return;

    self.isUserPullAndRefresh = NO;
    [self showAnimationView];

    self.state = TMAPULL_REFRESH_STATE_LOADING;

    // 改变contentOffset完全显示header，触发KVO监听
    [self setScrollViewContentOffset];

    [self.layer removeAllAnimations];

    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // 改变contentInfset，完全显示header
        [self keepRefreshViewStaying];
    } completion:^(BOOL finished) {
        [self doHandler];
    }];
}

- (void)setScrollViewContentOffset {
    UIEdgeInsets insets = self.scrollView.originContentInset;
    CGFloat top = self.pullRefreshLoadingHeight + insets.top;
    // 设置最终滚动位置
    CGPoint offset = self.scrollView.contentOffset;
    offset.y = -top;
    [self.scrollView setContentOffset:offset animated:NO];
}

/// 保持sectionheader停留
- (void)keepRefreshViewStaying {
    UIEdgeInsets insets = self.scrollView.originContentInset;
    CGFloat top = self.pullRefreshLoadingHeight + insets.top;
    UIEdgeInsets dest = UIEdgeInsetsMake(top, insets.left, insets.bottom, insets.right);
    [self setScrollViewContentInsetWithOutObserve:dest];
}

- (void)setScrollViewContentInsetWithOutObserve:(UIEdgeInsets)inset {

    if (_scrollView.tmaRefreshView && _scrollView.tmaRefreshView.isObservingContentInset) {
        @try {
            [_scrollView removeObserver:_scrollView.tmaRefreshView forKeyPath:@"contentInset"];
            [_scrollView removeObserver:_scrollView.tmaRefreshView forKeyPath:@"contentOffset"];
            _scrollView.tmaRefreshView.isObservingContentInset = NO;
        } @catch (NSException *exception) {}
    }

    _scrollView.contentInset = inset.top >= 0?inset:UIEdgeInsetsMake(0, inset.left, inset.bottom, inset.right);

    if (_scrollView.tmaRefreshView && !_scrollView.tmaRefreshView.isObservingContentInset) {
        @try {
            [_scrollView addObserver:_scrollView.tmaRefreshView forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
            [_scrollView addObserver:_scrollView.tmaRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            _scrollView.tmaRefreshView.isObservingContentInset = YES;
        } @catch (NSException *exception) {}
    }
}

#pragma mark - Scrollview PanGesturer Action
/*-----------------------------------------------*/
//    Scrollview PanGesturer Action - 手势控制
/*-----------------------------------------------*/
- (void)startObserve {
    _isObserving = YES;
    _isObservingContentInset = YES;
    @try {
        [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [_scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [_scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
    } @catch (NSException *exception) {
        
    }
}

- (void)removeObserve:(UIScrollView *)scrollView {
    _isObserving = NO;
    _isObservingContentInset = NO;
    @try {
        [scrollView removeObserver:self forKeyPath:@"contentInset"];
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"contentSize"];
    } @catch (NSException *exception) {
    }
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (void)setRefreshAnimateView:(UIView<TMARefreshAnimationDelegate> *)refreshAnimateView
{
    if (!refreshAnimateView || _refreshAnimateView == refreshAnimateView) {
        return;
    }
    
    if (self.state == TMAPULL_REFRESH_STATE_LOADING) {
        return;
    }
    
    if (_refreshAnimateView) {
        [_refreshAnimateView stopLoading];
    }
    
    if (_refreshAnimateView.superview) {
        [_refreshAnimateView removeFromSuperview];
    }
    
    _refreshAnimateView = refreshAnimateView;
    //[self addSubview:_refreshAnimateView];
    [self insertSubview:_refreshAnimateView atIndex:0];
}

- (void)setPullRefreshLoadingHeight:(CGFloat)pullRefreshLoadingHeight {
    
    _pullRefreshLoadingHeight = pullRefreshLoadingHeight;
    if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(configurePullRefreshLoadingHeight:)]) {
        [self.refreshAnimateView configurePullRefreshLoadingHeight:_pullRefreshLoadingHeight];
    }
}

- (void)setState:(TMAPullState)state
{
    if (state == _state) {
        return;
    }
    switch (state)
    {
        case TMAPULL_REFRESH_STATE_INIT:
            [self showAnimationView];
            break;
        case TMAPULL_REFRESH_STATE_LOADING:
            if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(startLoading)]) {
                [self.refreshAnimateView performSelector:@selector(startLoading)];
            }
            break;
        default:
            break;
    }
    
    if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(updateViewWithPullState:)]) {
        [self.refreshAnimateView updateViewWithPullState:state];
    }
    
    _state = state;
    [_scrollView tmaPullView:self stateChange:state];
}

- (void)setEnabled:(BOOL)enabled {
    self.hidden = !enabled;
    _enabled = enabled;
}

- (void)setScrollInsets:(BOOL)shouldDoHandler {
    [UIView animateWithDuration:self.secondsNeedScrollToLoading animations:^{
        if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(animationWithScrollViewBackToLoading)]) {
            [self.refreshAnimateView performSelector:@selector(animationWithScrollViewBackToLoading)];
        }
        [self keepRefreshViewStaying];
    } completion:^(BOOL finished) {
        if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(completionWithScrollViewBackToLoading)]) {
            [self.refreshAnimateView performSelector:@selector(completionWithScrollViewBackToLoading)];
        }
    }];
    
    if (shouldDoHandler) {
        BDPExecuteOnMainQueue(^{
            [self doHandler];
        });
    }
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)layoutSubviews {
    
    [UIView setAnimationsEnabled:NO];
    [super layoutSubviews];
    if (self.refreshAnimateView) {
        self.refreshAnimateView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    }
    [UIView setAnimationsEnabled:YES];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        if (self.isObserving) {
            [self removeObserve:(UIScrollView *) self.superview];
        }
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (newWindow) {
        if (self.state == TMAPULL_REFRESH_STATE_LOADING) {
            // 恢复动画
            if (self.refreshAnimateView && [self.refreshAnimateView respondsToSelector:@selector(startLoading)]) {
                [self.refreshAnimateView startLoading];
            }
        }
    }
}

@end
