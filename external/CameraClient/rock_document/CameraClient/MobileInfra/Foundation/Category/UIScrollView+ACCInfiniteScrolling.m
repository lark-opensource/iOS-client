//
//  UIScrollView+ACCInfiniteScrolling.m
//  CameraClient
//
//  Created by gongandy on 2018/1/16.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import "UIScrollView+ACCInfiniteScrolling.h"

#import <objc/runtime.h>

@interface ACCInfiniteScrollingView ()

@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, readwrite) CGFloat originalRightInset;
@property (nonatomic, readwrite) ACCInfiniteScrollingState state;
@property (nonatomic, copy) void (^infiniteScrollingHandler)(void);
@property (nonatomic, assign) CGSize originalContentSize;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

static char UIScrollViewInfiniteScrollingView;
static char UIScrollViewShouldPerformInfiniteScrollAtAbsoluteBottom;
static char InfiniteScrollingViewHeight;
static char InfiniteScrollingViewWidth;
static char HorizontalInfiniteScrolling;

@interface UIScrollView ()

@property (nonatomic, strong, readwrite) ACCInfiniteScrollingView *acc_infiniteScrollingView;
@property (nonatomic, assign) CGFloat acc_infiniteScrollingViewHeight;
@property (nonatomic, assign) CGFloat acc_infiniteScrollingViewWidth;
@property (nonatomic, assign) BOOL acc_horizontalInfiniteScrolling;

@end

@implementation UIScrollView (ACCInfiniteScrolling)

#pragma mark - Public

- (void)acc_addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler
{
    if (!self.acc_infiniteScrollingView) {
        self.acc_infiniteScrollingViewHeight = 60;
        self.acc_horizontalInfiniteScrolling = NO;
        ACCInfiniteScrollingView *view = [[ACCInfiniteScrollingView alloc] init];
        view.scrollView                = self;
        view.infiniteScrollingHandler  = actionHandler;
        view.originalBottomInset       = self.contentInset.bottom;
        view.frame = CGRectMake(0, self.contentSize.height, self.bounds.size.width, self.acc_infiniteScrollingViewHeight);
        [self addSubview:view];
        self.acc_infiniteScrollingView  = view;
        self.acc_showsInfiniteScrolling = YES;
    }
}

- (void)acc_addInfiniteScrollingWithViewHeight:(CGFloat)viewHeight actionHandler:(void (^)(void))actionHandler
{
    if (!self.acc_infiniteScrollingView) {
        self.acc_infiniteScrollingViewHeight = viewHeight;
        self.acc_horizontalInfiniteScrolling = NO;
        ACCInfiniteScrollingView *view = [[ACCInfiniteScrollingView alloc] init];
        view.scrollView                = self;
        view.infiniteScrollingHandler  = actionHandler;
        view.originalBottomInset       = self.contentInset.bottom;
        view.frame = CGRectMake(0, self.contentSize.height, self.bounds.size.width, viewHeight);
        [self addSubview:view];

        self.acc_infiniteScrollingView  = view;
        self.acc_showsInfiniteScrolling = YES;
    }
}

// 支持横向滚动无限加载，支持自定义宽度
- (void)acc_addInfiniteHorizontalScrollingWithViewWidth:(CGFloat)viewWidth actionHandler:(void (^)(void))actionHandler {
    if (!self.acc_infiniteScrollingView) {
        self.acc_infiniteScrollingViewWidth = viewWidth;
        self.acc_horizontalInfiniteScrolling = YES;
        ACCInfiniteScrollingView *view = [[ACCInfiniteScrollingView alloc] init];
        view.scrollView                = self;
        view.infiniteScrollingHandler  = actionHandler;
        view.originalRightInset = self.contentInset.right;
        view.frame = CGRectMake(self.contentSize.width, 0, viewWidth, self.bounds.size.height);
        [self addSubview:view];
        self.acc_infiniteScrollingView  = view;
        self.acc_showsInfiniteScrolling = YES;
    }
}

- (void)acc_triggerInfiniteScrolling
{
    self.acc_infiniteScrollingView.state = ACCInfiniteScrollingStateTriggered;
    [self.acc_infiniteScrollingView startAnimating];
}

#pragma mark - Accessors

- (ACCInfiniteScrollingView *)acc_infiniteScrollingView
{
    return objc_getAssociatedObject(self, &UIScrollViewInfiniteScrollingView);
}

- (void)setAcc_infiniteScrollingView:(ACCInfiniteScrollingView *)acc_infiniteScrollingView {
    [self willChangeValueForKey:@"UIScrollViewInfiniteScrollingView"];
    objc_setAssociatedObject(self, &UIScrollViewInfiniteScrollingView, acc_infiniteScrollingView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"UIScrollViewInfiniteScrollingView"];
}

- (CGFloat)acc_infiniteScrollingViewHeight {
    NSNumber *value = objc_getAssociatedObject(self, &InfiniteScrollingViewHeight);
    return [value floatValue];
}

- (void)setAcc_infiniteScrollingViewHeight:(CGFloat)acc_infiniteScrollingViewHeight {
    NSNumber *value = [NSNumber numberWithFloat:acc_infiniteScrollingViewHeight];
    objc_setAssociatedObject(self, &InfiniteScrollingViewHeight, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)acc_infiniteScrollingViewWidth {
    NSNumber *value = objc_getAssociatedObject(self, &InfiniteScrollingViewWidth);
    return [value floatValue];
}

- (void)setAcc_infiniteScrollingViewWidth:(CGFloat)acc_infiniteScrollingViewWidth {
    NSNumber *value = [NSNumber numberWithFloat:acc_infiniteScrollingViewWidth];
    objc_setAssociatedObject(self, &InfiniteScrollingViewWidth, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)acc_horizontalInfiniteScrolling {
    NSNumber *value = objc_getAssociatedObject(self, &HorizontalInfiniteScrolling);
    return [value boolValue];
}

- (void)setAcc_horizontalInfiniteScrolling:(BOOL)acc_horizontalInfiniteScrolling {
    NSNumber *value = [NSNumber numberWithBool:acc_horizontalInfiniteScrolling];
    objc_setAssociatedObject(self, &HorizontalInfiniteScrolling, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)acc_showsInfiniteScrolling {
    return !self.acc_infiniteScrollingView.hidden;
}

- (void)setAcc_showsInfiniteScrolling:(BOOL)acc_showsInfiniteScrolling {
    if (!self.acc_infiniteScrollingView) {
        return;
    }

    self.acc_infiniteScrollingView.hidden = !acc_showsInfiniteScrolling;

    if (!acc_showsInfiniteScrolling) {
        if (self.acc_infiniteScrollingView.isObserving) {
            [self removeObserver:self.acc_infiniteScrollingView forKeyPath:@"contentOffset"];
            [self removeObserver:self.acc_infiniteScrollingView forKeyPath:@"contentSize"];
            self.acc_infiniteScrollingView.isObserving = NO;
            [self.acc_infiniteScrollingView resetScrollViewContentInset];
        }
    } else {
        if (!self.acc_infiniteScrollingView.isObserving) {
            [self addObserver:self.acc_infiniteScrollingView
                   forKeyPath:@"contentOffset"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
            [self addObserver:self.acc_infiniteScrollingView
                   forKeyPath:@"contentSize"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
            self.acc_infiniteScrollingView.isObserving = YES;
            [self.acc_infiniteScrollingView setScrollViewContentInsetForInfiniteScrolling];
            [self.acc_infiniteScrollingView setNeedsLayout];
            
            if (self.acc_horizontalInfiniteScrolling) {
                self.acc_infiniteScrollingView.frame =
                CGRectMake(self.contentSize.width, 0, self.acc_infiniteScrollingViewWidth, self.acc_infiniteScrollingView.bounds.size.height);
            } else {
                self.acc_infiniteScrollingView.frame =
                CGRectMake(0, self.contentSize.height, self.acc_infiniteScrollingView.bounds.size.width,
                           self.acc_infiniteScrollingViewHeight);
            }
        }
    }
}

- (void)setAcc_infiniteScrollPosition:(ACCInfiniteScrollPosition)acc_infiniteScrollPosition {
    objc_setAssociatedObject(self, &UIScrollViewShouldPerformInfiniteScrollAtAbsoluteBottom,
                             @(acc_infiniteScrollPosition), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (ACCInfiniteScrollPosition)acc_infiniteScrollPosition {
    id acc_shouldPerformInfiniteScrollAtAbsoluteBottom =
        objc_getAssociatedObject(self, &UIScrollViewShouldPerformInfiniteScrollAtAbsoluteBottom);
    if (acc_shouldPerformInfiniteScrollAtAbsoluteBottom) {
        return [acc_shouldPerformInfiniteScrollAtAbsoluteBottom integerValue];
    }
    return ACCInfiniteScrollPositionFarFromBottom;
}

@end

@implementation ACCInfiniteScrollingView

@synthesize infiniteScrollingHandler;
@synthesize state                 = _state;
@synthesize scrollView            = _scrollView;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask           = UIViewAutoresizingFlexibleWidth;
        self.state                      = ACCInfiniteScrollingStateStopped;
        self.enabled                    = YES;
        self.originalContentSize = CGSizeZero;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *) self.superview;
        if (scrollView.acc_showsInfiniteScrolling) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                self.isObserving = NO;
            }
        }
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    if (self.scrollView.acc_horizontalInfiniteScrolling) {
        currentInsets.right = self.originalRightInset;
    } else {
        currentInsets.bottom = self.originalBottomInset;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    if (self.scrollView.acc_horizontalInfiniteScrolling) {
        currentInsets.right = self.originalRightInset + self.scrollView.acc_infiniteScrollingViewWidth;
    } else {
        currentInsets.bottom = self.originalBottomInset + self.scrollView.acc_infiniteScrollingViewHeight;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    UIScrollView *scrollView = self.scrollView;

    [scrollView layoutIfNeeded];

    CGPoint contentOffset = scrollView.contentOffset;

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         scrollView.contentInset  = contentInset;
                         scrollView.contentOffset = contentOffset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    UIScrollView *scrollView = self.scrollView;
    if ([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if ([keyPath isEqualToString:@"contentSize"]) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
        if (self.scrollView.acc_horizontalInfiniteScrolling) {
            self.frame = CGRectMake(scrollView.contentSize.width, 0, self.scrollView.acc_infiniteScrollingViewWidth,  self.bounds.size.height);
        } else {
            self.frame = CGRectMake(0, scrollView.contentSize.height, self.bounds.size.width, self.scrollView.acc_infiniteScrollingViewHeight);
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (self.state != ACCInfiniteScrollingStateLoading && self.enabled) {
        UIScrollView *scrollView             = self.scrollView;
    
        CGFloat scrollViewBoundsHeightOffset = 6.0f;
        switch (scrollView.acc_infiniteScrollPosition) {
            case ACCInfiniteScrollPositionAtAbsoluteBottom:
                scrollViewBoundsHeightOffset = 1.0f;
                break;
            case ACCInfiniteScrollPositionNearBottom:
                scrollViewBoundsHeightOffset = 1.5f;
                break;
            case ACCInfiniteScrollPositionFarFromBottom:
                break;
        }

        if (self.scrollView.acc_horizontalInfiniteScrolling) {
            CGFloat scrollViewContentWidth = scrollView.contentSize.width;
            CGFloat scrollOffsetThreshold = MAX(scrollViewContentWidth - scrollView.bounds.size.width * scrollViewBoundsHeightOffset, 0.0f);
            if (self.state == ACCInfiniteScrollingStateTriggered) {
                self.state = ACCInfiniteScrollingStateLoading;
            } else if (contentOffset.x > scrollOffsetThreshold && self.state == ACCInfiniteScrollingStateStopped) {
                if (self.originalContentSize.width > self.scrollView.contentSize.width) {
                    return;
                }
                self.state = ACCInfiniteScrollingStateTriggered;
            } else if (contentOffset.x < scrollOffsetThreshold && self.state != ACCInfiniteScrollingStateStopped) {
                self.state = ACCInfiniteScrollingStateStopped;
            }
        } else {
            CGFloat scrollViewContentHeight = scrollView.contentSize.height;
            CGFloat scrollOffsetThreshold = MAX(scrollViewContentHeight - scrollView.bounds.size.height * scrollViewBoundsHeightOffset, 0.0f);
            if (self.state == ACCInfiniteScrollingStateTriggered) {
                self.state = ACCInfiniteScrollingStateLoading;
            } else if (contentOffset.y > scrollOffsetThreshold && self.state == ACCInfiniteScrollingStateStopped) {
                if (self.originalContentSize.height > self.scrollView.contentSize.height) {
                    return;
                }
                self.state = ACCInfiniteScrollingStateTriggered;
            } else if (contentOffset.y < scrollOffsetThreshold && self.state != ACCInfiniteScrollingStateStopped) {
                self.state = ACCInfiniteScrollingStateStopped;
            }
        }
    }
}

#pragma mark -

- (void)triggerRefresh {
    self.state = ACCInfiniteScrollingStateTriggered;
    self.state = ACCInfiniteScrollingStateLoading;
}

- (void)startAnimating {
    self.state = ACCInfiniteScrollingStateLoading;
}

- (void)stopAnimating {
    self.state = ACCInfiniteScrollingStateStopped;
}

- (void)setState:(ACCInfiniteScrollingState)newState {
    if (self.scrollView.acc_horizontalInfiniteScrolling) {
        if (newState == ACCInfiniteScrollingStateStopped
            && self.scrollView.contentSize.width < self.scrollView.bounds.size.width
            && self.infiniteScrollingHandler
            && self.enabled
            && !CGSizeEqualToSize(self.originalContentSize, self.scrollView.contentSize)) {
            self.originalContentSize = self.scrollView.contentSize;
            self.infiniteScrollingHandler();
        }
        if (newState == ACCInfiniteScrollingStateStopped && self.originalContentSize.width > self.scrollView.contentSize.width) {
            self.originalContentSize = self.scrollView.contentSize;
        }
    } else {
        if (newState == ACCInfiniteScrollingStateStopped
            && self.scrollView.contentSize.height < self.scrollView.bounds.size.height
            && self.infiniteScrollingHandler
            && self.enabled
            && !CGSizeEqualToSize(self.originalContentSize, self.scrollView.contentSize)) {
            self.originalContentSize = self.scrollView.contentSize;
            self.infiniteScrollingHandler();
        }
        //更新scrollview导致contentSize减小的场合、需要立刻重设originalContentSize
        if (newState == ACCInfiniteScrollingStateStopped && self.originalContentSize.height > self.scrollView.contentSize.height) {
            self.originalContentSize = self.scrollView.contentSize;
        }
    }
    
    if (_state == newState)
        return;

    ACCInfiniteScrollingState previousState = _state;
    _state                                  = newState;

    if (previousState == ACCInfiniteScrollingStateTriggered && newState == ACCInfiniteScrollingStateLoading &&
        self.infiniteScrollingHandler && self.enabled) {
        self.originalContentSize = self.scrollView.contentSize;
        self.infiniteScrollingHandler();
    }
}

- (void)resetOriginalContentSize
{
    self.originalContentSize = CGSizeZero;
}

@end
