//
//  ACCPanelAnimator.h
//  CameraClient
//
//  Created by wishes on 2020/2/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ACCPanelAnimationShow,
    ACCPanelAnimationDismiss
} ACCPanelAnimationType;

@protocol ACCPanelAnimator;

typedef void(^ACCPanelAnimatorBlock)(id<ACCPanelAnimator> animator);

@protocol ACCPanelAnimator <NSObject>

@property (nonatomic, assign) ACCPanelAnimationType type;

@property (nonatomic, strong) UIView* targetView;

@property (nonatomic, strong) UIView* containerView;

@property (nonatomic, copy) ACCPanelAnimatorBlock animationWillStart;

@property (nonatomic, copy) ACCPanelAnimatorBlock animationDidEnd;

- (void)animate;

@end

@interface ACCPanelSlideDownAnimator : NSObject <ACCPanelAnimator>

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat targetAnimationHeight;

@property (nonatomic, strong) UIView* containerView;

@end


@interface ACCPanelSlideUpAnimator : NSObject <ACCPanelAnimator>

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat targetAnimationHeight;

@property (nonatomic, strong) UIView* containerView;

@end


NS_ASSUME_NONNULL_END
