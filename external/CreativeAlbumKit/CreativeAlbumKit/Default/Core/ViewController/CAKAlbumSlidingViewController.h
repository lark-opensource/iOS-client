//
//  CAKAlbumSlidingViewController.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/1.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CAKAlbumSlidingVCTransitionType) {
    CAKAlbumSlidingVCTransitionTypeTapTab = 0,
    CAKAlbumSlidingVCTransitionTypeScroll = 1,
};

@class CAKAlbumSlidingViewController, CAKAlbumSlidingTabBarView, CAKAlbumSlidingScrollView;

@protocol CAKAlbumSlidingViewControllerDelegate <NSObject>

- (NSInteger)numberOfControllers:(CAKAlbumSlidingViewController * _Nonnull)slidingController;
- (UIViewController * _Nullable)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController viewControllerAtIndex:(NSInteger)index;

@optional
- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController didSelectIndex:(NSInteger)index;

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController didSelectIndex:(NSInteger)index transitionType:(CAKAlbumSlidingVCTransitionType)transitionType;

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController willTransitionToViewController:(UIViewController * _Nonnull)pendingViewController;

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController willTransitionToViewController:(UIViewController * _Nonnull)pendingViewController transitionType:(CAKAlbumSlidingVCTransitionType)transitionType;

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController didFinishTransitionToIndex:(NSUInteger)index; // same index after transition will call this as well

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController didFinishTransitionFromPreviousViewController:(UIViewController * _Nonnull)previousViewController currentViewController:(UIViewController * _Nonnull)currentViewController;

- (void)slidingViewController:(CAKAlbumSlidingViewController * _Nonnull)slidingViewController didFinishTransitionFromPreviousIndex:(NSInteger)previousIndex currentIndex:(NSInteger)currentIndex transitionType:(CAKAlbumSlidingVCTransitionType)transitionType;

- (void)slidingViewControllerDidScroll:(UIScrollView * _Nonnull)scrollView;

@end

@interface CAKAlbumSlidingViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong, nullable) CAKAlbumSlidingTabBarView *tabbarView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL slideEnabled;
@property (nonatomic, assign) BOOL needAnimationWithTapTab;
@property (nonatomic, weak, nullable) id<CAKAlbumSlidingViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldAdjustScrollInsets;
@property (nonatomic, strong, nullable) CAKAlbumSlidingScrollView *contentScrollView;
@property (nonatomic, assign) BOOL enableSwipeCardEffect; //卡片横向切换效果

- (instancetype _Nonnull)initWithSelectedIndex:(NSInteger)index;
- (void)reloadViewControllers;
- (UIViewController * _Nullable)controllerAtIndex:(NSInteger)index;
- (Class _Nonnull)scrollViewClass;
- (NSInteger)currentScrollPage;
- (NSInteger)numberOfControllers;
- (NSArray<UIView *> * _Nullable)visibleViews;
- (NSArray * _Nullable)currentViewControllers;
- (void)insertAtFrontWithViewController:(UIViewController * _Nonnull)viewController;
- (void)replaceViewController:(UIViewController * _Nonnull)newVC atIndex:(NSInteger)index;
- (void)appendViewController:(UIViewController * _Nonnull)viewController;

@end


