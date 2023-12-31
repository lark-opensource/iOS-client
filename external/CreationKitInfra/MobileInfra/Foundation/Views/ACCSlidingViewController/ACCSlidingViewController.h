//
//  ACCSlidingViewController.h
//  CameraClient
//
//  Created by gongyanyun  on 2018/6/22.
//

#import <UIKit/UIKit.h>
#import "ACCSlidingTabbarProtocol.h"
#import "ACCSlidingScrollView.h"

typedef NS_ENUM(NSInteger, ACCSlidingVCTransitionType) {
    ACCSlidingVCTransitionTypeTapTab = 0,
    ACCSlidingVCTransitionTypeScroll = 1,
};

@class ACCSlidingViewController;

@protocol ACCSlidingViewControllerDelegate <NSObject>

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController;
- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index;

@optional
- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index transitionType:(ACCSlidingVCTransitionType)transitionType;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController willTransitionToViewController:(UIViewController *)pendingViewController;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController willTransitionToViewController:(UIViewController *)pendingViewController transitionType:(ACCSlidingVCTransitionType)transitionType;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didFinishTransitionToIndex:(NSUInteger)index; // same index after transition will call this as well

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didFinishTransitionFromPreviousViewController:(UIViewController *)previousViewController currentViewController:(UIViewController *)currentViewController;

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didFinishTransitionFromPreviousIndex:(NSInteger)previousIndex currentIndex:(NSInteger)currentIndex transitionType:(ACCSlidingVCTransitionType)transitionType;

- (void)slidingViewControllerDidScroll:(UIScrollView *)scrollView;

@end

@interface ACCSlidingViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, strong) UIView<ACCSlidingTabbarProtocol> *tabbarView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL slideEnabled;
@property (nonatomic, assign) BOOL needAnimationWithTapTab;
@property (nonatomic, weak) id<ACCSlidingViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldAdjustScrollInsets;
@property (nonatomic, strong) ACCSlidingScrollView *contentScrollView;
@property (nonatomic, assign) BOOL enableSwipeCardEffect;

- (instancetype)initWithSelectedIndex:(NSInteger)index;
- (void)reloadViewControllers;
- (UIViewController *)controllerAtIndex:(NSInteger)index;
- (Class)scrollViewClass;
- (NSInteger)currentScrollPage;
- (NSInteger)numberOfControllers;
- (NSArray<UIView *> *)visibleViews;
- (NSArray *)currentViewControllers;
- (void)insertAtFrontWithViewController:(UIViewController *)viewController;
- (void)replaceViewController:(UIViewController *)newVC atIndex:(NSInteger)index;
- (void)appendViewController:(UIViewController *)viewController;

@end
