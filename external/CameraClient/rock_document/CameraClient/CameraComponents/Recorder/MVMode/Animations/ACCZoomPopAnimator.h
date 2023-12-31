//
//  ACCZoomPopAnimator.h
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCZoomPopAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL interactionInProgress;

- (void)updateAnimationWithLocation:(CGPoint)currentLocation startLocation:(CGPoint)startLocation;

- (void)finishAnimation;

- (void)cancelAnimation;

@end

NS_ASSUME_NONNULL_END
