//
//  HTSVideoProgressView.h
//  Pods
//
//  Created by 何海 on 16/7/4.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AWEStudioProgressView : UIView

@property (nonatomic, strong) UIColor *progressTintColor;
@property (nonatomic, strong) UIColor *trackTintColor;
@property (nonatomic, assign) BOOL rounded;

@end


@interface HTSVideoProgressView : AWEStudioProgressView

@property (nonatomic, weak) UILabel *standardDurationLabel;
@property (nonatomic, assign) BOOL isLeftEnd;
@property (nonatomic, assign) BOOL isRightEnd;
//@property (nonatomic, assign) BOOL hideMarkAtRightEnd;
- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated;

- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime;

- (void)layoutSegments:(NSArray*)segments toalTime:(CGFloat)totalTime;

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration;

- (void)blinkMarkAtCurrentProgress:(BOOL)on;
- (void)blinkProgressBarOnce;
@end
