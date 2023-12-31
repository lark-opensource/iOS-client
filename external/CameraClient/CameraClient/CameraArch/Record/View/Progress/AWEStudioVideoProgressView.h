//
//  AWEStudioVideoProgressView.h
//  Pods
//
//  Created by homeboy on 2019/4/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEVideoProgressViewProtocol <NSObject>
@property (nonatomic, assign, readonly) float progress;

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated;

- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime;

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration;
@optional
- (void)updateViewWithProgress:(CGFloat)progress
                         marks:(NSArray *)marks
                      duration:(double)duration
                     totalTime:(CGFloat)totalTime
                      animated:(BOOL)animated;

@end

@protocol AWEVideoProgressViewColorState <NSObject>

@property (nonatomic, strong) UIColor *trackTintColor;
@property (nonatomic, readonly, nullable) UIColor *originTrackTintColor;

@end

@protocol AWEVideoProgressReshootProtocol <NSObject>

- (void)setReshootTimeFrom:(NSTimeInterval)startTime to:(NSTimeInterval)endTime totalDuration:(NSTimeInterval)totalDuration;

@end

@interface AWEStudioVideoProgressView : UIView<AWEVideoProgressViewProtocol, AWEVideoProgressViewColorState>

@property (nonatomic, strong, readonly) UILabel *standardDurationLabel;

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated;

- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime;

- (void)updateViewWithProgress:(CGFloat)progress
                         marks:(NSArray *)marks
                      duration:(double)duration
                     totalTime:(CGFloat)totalTime
                      animated:(BOOL)animated;

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration;

@end

NS_ASSUME_NONNULL_END
