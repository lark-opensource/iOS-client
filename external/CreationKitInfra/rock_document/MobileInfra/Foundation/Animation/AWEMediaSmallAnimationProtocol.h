//
//  AWEMediaSmallAnimationProtocol.h
//  Aweme
//
// Created by Xuxu on December 24, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <Foundation/Foundation.h>


@protocol AWEMediaBigAnimationProtocol <NSObject>

- (UIView *)mediaBigMediaSnap;
- (UIView *)mediaBigButtonsContainerSnap;// Each time you enter bigvc, you can take a screenshot only once. Avoid taking a screenshot during transition, and you will cut in the enlarged button
- (UIView *)mediaBigButtonsContainer;
- (CGRect)mediaBigMediaFrame;

@end


@protocol AWEMediaSmallAnimationProtocol <NSObject>

@required
- (UIView *)mediaSmallMediaContainer;
- (CGRect)mediaSmallMediaContainerFrame;

- (UIView *)mediaSmallBottomView; // Wrap a view to deal with the overall animation at the bottom

@optional
- (void)doSomethingAfterSnap;
- (CGAffineTransform)mediaSmallMediaContainerTransform;
- (BOOL)mediaDisplayImmediately;
- (NSArray<UIView *> *)displayTopViews;
- (CGFloat)bottomViewTransitionDist;
- (BOOL)isBottomViewFadeOut;

@end

