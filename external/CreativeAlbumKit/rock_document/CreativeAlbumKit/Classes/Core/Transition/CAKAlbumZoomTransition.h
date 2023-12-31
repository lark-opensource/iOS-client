//
//  CAKAlbumZoomTransition.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAKAlbumTransitionContextProvider.h"
#import "CAKAlbumTransitionDelegateProtocol.h"
#import "CAKAlbumZoomTransitionDelegate.h"

@protocol CAKAlbumZoomTransitionOuterContextProvider

- (NSInteger)zoomTransitionItemOffset;
- (UIView * _Nullable)zoomTransitionStartViewForOffset:(NSInteger)offset;

@optional
- (BOOL)zoomTransitionWantsTabBarAnimation; // frame
- (BOOL)zoomTransitionWantsTabBarAlphaAnimation; // alpha animation
- (BOOL)zoomTransitionWantsFromVCAnimation;
- (void)zoomTransitionMigrationDidEndForView:(UIView * _Nullable)migratedView;
- (UIView * _Nullable)targetViewControllerSnapshotView;
- (CGRect)targetViewFrame;
- (NSTimeInterval)tabbarAnimationDuration;

@end

@protocol CAKAlbumZoomTransitionInnerContextProvider

@optional
- (UIView * _Nullable)zoomTransitionEndView;
- (CAKAlbumTransitionTriggerDirection)zoomTransitionAllowedTriggerDirection;
- (BOOL)zoomTransitionWantsBlackMaskView;
- (BOOL)zoomTransitionWantsViewMigration;
- (BOOL)zoomTransitionWantsTabBarAlphaAnimation; // alpha
- (void)zoomTransitionWillStartForView:(UIView * _Nullable)migratedView;
- (NSInteger)zoomTransitionItemOffset;
- (BOOL)zoomTransitionWantsRemoveSpringAnimation;
- (NSTimeInterval)animationDuration;
- (NSTimeInterval)tabbarAnimationDuration;
- (BOOL)zoomTransitionForbidShowToVCSnapshot;

@end

@interface CAKAlbumTransitionContext : NSObject

@property (nonatomic, assign) CAKAlbumTransitionTriggerDirection triggerDirection;
@property (nonatomic, strong, nullable) UIViewController *fromViewController;
@property (nonatomic, strong, nullable) UIViewController *toViewController;
@property (nonatomic, strong, nullable) id fromContextProvider;
@property (nonatomic, strong, nullable) id toContextProvider;
@property (nonatomic, strong, nullable) id<CAKAlbumTransitionContextProvider> contextProvider;

@end

@interface CAKMagnifyTransition : NSObject<CAKAlbumTransitionContextProvider>

@end

@interface CAKShrinkTransition : NSObject<CAKAlbumTransitionContextProvider>

@end

@interface CAKInteractiveShrinkTransition : NSObject<CAKAlbumTransitionContextProvider>

- (instancetype _Nonnull)initWithTransitionDelegate:(id<CAKAlbumTransitionDelegateProtocol> _Nullable)transitionDelegate;

@end
