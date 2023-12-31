//
//  BDPPresentAnimation.h
//  Timor
//
//  Created by MacPu on 2018/10/10.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPPresentAnimationStype) {
    BDPPresentAnimationStypeUpDown,
    BDPPresentAnimationStypeRightLeft
};

@interface BDPPresentAnimation : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL screenEdgePopMode;
@property (nonatomic, assign) BDPPresentAnimationStype style;
@property (nonatomic, strong, readonly) UIPercentDrivenInteractiveTransition *interactive;
@property (nonatomic, assign) UINavigationControllerOperation operation;

@end

NS_ASSUME_NONNULL_END
