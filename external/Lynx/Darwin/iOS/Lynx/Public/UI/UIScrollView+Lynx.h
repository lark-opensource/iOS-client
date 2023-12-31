//
//  UIScrollView+Lynx.h
//  Lynx
//
//  Copyright 2022 The Lynx Authors. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LynxScrollViewTouchBehavior) {
  LynxScrollViewTouchBehaviorNone = 0,
  LynxScrollViewTouchBehaviorForbid,
  LynxScrollViewTouchBehaviorPause,
  LynxScrollViewTouchBehaviorStop,
};

typedef BOOL (^UIScrollViewLynxCompletion)(BOOL scrollEnabledAtStart);

typedef CGPoint (^UIScrollViewLynxProgressInterception)(double timeProgress, double distProgress,
                                                        CGPoint contentOffset);
typedef double (^UIScrollViewLynxTimingFunction)(double input);

@interface UIScrollView (Lynx)

@property(nonatomic, assign) BOOL scrollEnableFromLynx;

/**
 scroll a UIScrollView with custom duration
 @param contentOffset target content offset
 @param behavior LynxScrollViewTouchBehavior
 @param duration scroll duration
 @param interval frame interval, default value is zero
 @param interception custom your own progress if needed
 @param callback called while scroll finished
 */
- (void)setContentOffset:(CGPoint)contentOffset
                behavior:(LynxScrollViewTouchBehavior)behavior
                duration:(NSTimeInterval)duration
                interval:(NSTimeInterval)interval
                progress:(_Nullable UIScrollViewLynxProgressInterception)interception
                complete:(_Nullable UIScrollViewLynxCompletion)callback;

/**
 scroll a UIScrollView with custom duration, with easeOut function, used to apply fling effection
 @param contentOffset target content offset
 @param behavior LynxScrollViewTouchBehavior
 @param duration scroll duration
 @param interval frame interval, default value is zero
 @param callback called while scroll finished
 */
- (void)scrollToTargetContentOffset:(CGPoint)contentOffset
                           behavior:(LynxScrollViewTouchBehavior)behavior
                           duration:(NSTimeInterval)duration
                           interval:(NSTimeInterval)interval
                           complete:(_Nullable UIScrollViewLynxCompletion)callback;

/**
 scroll a UIScrollView with a fixed rate
 @param rate scroll distance in every frame
 @param behavior LynxScrollViewTouchBehavior
 @param interval frame interval, default value is zero
 @param autoStop stop auto scroll if reach the bounds
 @param isVertical is vertical
 */
- (void)autoScrollWithRate:(CGFloat)rate
                  behavior:(LynxScrollViewTouchBehavior)behavior
                  interval:(NSTimeInterval)interval
                  autoStop:(BOOL)autoStop
                  vertical:(BOOL)isVertical;

- (void)stopScroll;
@end

NS_ASSUME_NONNULL_END
