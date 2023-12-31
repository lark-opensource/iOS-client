//
//  ACCPanelViewController.m
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//
#import "ACCPanelViewController.h"
#import "ACCPanelAnimator.h"

// weakify
#ifndef btd_keywordify
#if DEBUG
    #define btd_keywordify autoreleasepool {}
#else
    #define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) btd_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) btd_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) btd_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) btd_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

// queue
#ifndef acc_infra_queue_async_safe
#define acc_infra_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
block();\
} else {\
dispatch_async(queue, block);\
}
#endif

#ifndef acc_infra_main_async_safe
#define acc_infra_main_async_safe(block) acc_infra_queue_async_safe(dispatch_get_main_queue(), block)
#endif

@interface ACCPanelViewController ()

@property (nonatomic, strong) NSHashTable *observers;
@property (nonatomic, strong) NSHashTable *animators;
@property (nonatomic, weak) UIView *containerView;

@end

@implementation ACCPanelViewController

- (instancetype)initWithContainerView:(UIView *)contaienrView
{
    if (self = [super init]) {
        _containerView = contaienrView;
        _observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _animators = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

- (void)registerObserver:(id<ACCPanelViewDelegate>)observer
{
    if (![self.observers containsObject:observer] && [observer conformsToProtocol:@protocol(ACCPanelViewDelegate)]) {
        [self.observers addObject:observer];
    }
}

- (void)unregisterObserver:(id<ACCPanelViewDelegate>)observer
{
    [self.observers removeObject:observer];
}

- (void)removeAllObserver
{
    [self.observers removeAllObjects];
}


- (void)animatePanelView:(id<ACCPanelViewProtocol>)panelView withAnimator:(id<ACCPanelAnimator>)animator {
    UIView *targetPanelView = nil;
    if ([panelView isKindOfClass:[UIViewController class]]) {
        targetPanelView = [(UIViewController *)panelView view];
    } else if ([panelView isKindOfClass:[UIView class]]) {
        targetPanelView = (UIView *)panelView;
    }
    [self.animators addObject:animator];
    animator.targetView = targetPanelView;
    animator.containerView = self.containerView;
    animator.animationWillStart = ^(id<ACCPanelAnimator> animator){
        if ([panelView respondsToSelector:@selector(transitionStart)]) {
           [panelView transitionStart];
        }
        if (animator.type == ACCPanelAnimationShow) {
           [self notifyObeserverWillShowPanelView:panelView];
        } else {
           [self notifyObeserverWillDismissPanelView:panelView];
        }
    };
    animator.animationDidEnd = ^(id<ACCPanelAnimator> animator){
        if ([panelView respondsToSelector:@selector(transitionEnd)]) {
            [panelView transitionEnd];
        }
        if (animator.type == ACCPanelAnimationShow) {
            [self notifyObeserverDidShowPanelView:panelView];
        } else {
            [self notifyObeserverDidDismissPanelView:panelView];
             [targetPanelView removeFromSuperview];
        }
        if ([self.animators containsObject:animator]) {
            [self.animators removeObject:animator];
        }
    };
    [animator animate];
}

- (void)dismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    NSTimeInterval duration = 0;
    [self dismissPanelView:panelView duration:duration];
}

- (void)dismissPanelView:(id<ACCPanelViewProtocol>)panelView duration:(NSTimeInterval)duration
{
    ACCPanelSlideDownAnimator* animator = [ACCPanelSlideDownAnimator new];
    animator.targetAnimationHeight = panelView.panelViewHeight;
    animator.containerView = self.containerView;
    animator.duration = duration;
    [self animatePanelView:panelView withAnimator:animator];
}

- (void)showPanelView:(id<ACCPanelViewProtocol>)panelView
{
    NSTimeInterval duration = 0;
    [self showPanelView:panelView duration:duration];
}

- (void)showPanelView:(id<ACCPanelViewProtocol>)panelView duration:(NSTimeInterval)duration
{
    UIView *targetPanelView = nil;
    if ([panelView isKindOfClass:[UIViewController class]]) {
        targetPanelView = [(UIViewController *)panelView view];
    } else if ([panelView isKindOfClass:[UIView class]]) {
        targetPanelView = (UIView *)panelView;
    }
    [self.containerView addSubview:targetPanelView];
    [self.containerView bringSubviewToFront:targetPanelView];
    ACCPanelSlideUpAnimator* animator = [ACCPanelSlideUpAnimator new];
    animator.targetAnimationHeight = panelView.panelViewHeight;
    animator.containerView = self.containerView;
    animator.duration = duration;
    [self animatePanelView:panelView withAnimator:animator];
}

- (void)notifyObeserverWillShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    for (id<ACCPanelViewDelegate> observer in self.observers) {
        if ([observer respondsToSelector:@selector(panelViewController:willShowPanelView:)]) {
             [observer panelViewController:self willShowPanelView:panelView];
        }
    }
    
    if ([panelView respondsToSelector:@selector(panelWillShow)]) {
        @weakify(panelView);
        acc_infra_main_async_safe(^{
            @strongify(panelView);
            [panelView panelWillShow];
        });
    }
}

- (void)notifyObeserverDidShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    for (id<ACCPanelViewDelegate> observer in self.observers) {
        if ([observer respondsToSelector:@selector(panelViewController:didShowPanelView:)]) {
             [observer panelViewController:self didShowPanelView:panelView];
        }
    }
    
    if ([panelView respondsToSelector:@selector(panelDidShow)]) {
        @weakify(panelView);
        acc_infra_main_async_safe(^{
            @strongify(panelView);
            [panelView panelDidShow];
        });
    }
}

- (void)notifyObeserverWillDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    for (id<ACCPanelViewDelegate> observer in self.observers) {
        if ([observer respondsToSelector:@selector(panelViewController:willDismissPanelView:)]) {
             [observer panelViewController:self willDismissPanelView:panelView];
        }
    }
    
    if ([panelView respondsToSelector:@selector(panelWillDismiss)]) {
        @weakify(panelView);
        acc_infra_main_async_safe(^{
            @strongify(panelView);
            [panelView panelWillDismiss];
        });
    }
}

- (void)notifyObeserverDidDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    for (id<ACCPanelViewDelegate> observer in self.observers) {
        if ([observer respondsToSelector:@selector(panelViewController:didDismissPanelView:)]) {
             [observer panelViewController:self didDismissPanelView:panelView];
        }
    }
    
    if ([panelView respondsToSelector:@selector(panelDidDismiss)]) {
        @weakify(panelView);
        acc_infra_main_async_safe(^{
            @strongify(panelView);
            [panelView panelDidDismiss];
        });
    }
}


@end
