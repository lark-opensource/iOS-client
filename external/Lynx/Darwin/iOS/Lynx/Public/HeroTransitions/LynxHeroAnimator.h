// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxHeroAnimatorDelegate <NSObject>

- (void)updateProgress:(double)progress;
- (void)complete:(BOOL)finished;

@end

@interface LynxHeroAnimator : NSObject
@property(nonatomic, nullable, weak) id<LynxHeroAnimatorDelegate> delegate;
@property(nonatomic, assign) NSTimeInterval timePassed;
@property(nonatomic, assign) NSTimeInterval totalTime;
@property(nonatomic, assign) BOOL isReversed;

- (void)startWithTimePassed:(NSTimeInterval)timePassed
                  totalTime:(NSTimeInterval)totalTime
                 isReversed:(BOOL)isReversed;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
