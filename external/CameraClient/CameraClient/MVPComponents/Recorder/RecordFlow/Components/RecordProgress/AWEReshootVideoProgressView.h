//
//  AWEReshootVideoProgressView.h
//  AWEStudio
//
//  Created by Shen Chen on 2019/10/28.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEStudioVideoProgressView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEReshootVideoProgressView : UIView<AWEVideoProgressViewProtocol, AWEVideoProgressViewColorState, AWEVideoProgressReshootProtocol>

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated;

- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime;

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration;

- (void)blinkMarkAtCurrentProgress:(BOOL)on;
- (void)blinkReshootProgressBarOnce;
@end

NS_ASSUME_NONNULL_END
