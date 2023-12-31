//
//  AWELyricRollingTextView.h
//  RollingTextViewDemo
//
//  Created by 赖霄冰 on 2019/1/9.
//  Copyright © 2019 赖霄冰. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AWEMusicSelectItem,AWEVideoPublishViewModel;
@interface AWELyricRollingTextView : UIView

@property (nonatomic, assign, readonly) CGFloat distance;

- (void)configureWithFont:(UIFont *)font textColor:(UIColor *)textColor;
- (void)updateWithRollingText:(NSString *)text;
- (void)startAnimatingWithDuration:(NSTimeInterval)duration;
- (void)startAnimatingWithDuration:(NSTimeInterval)duration andDelay:(NSTimeInterval)delay;
- (void)stopAnimatingWithCompletion:(void (^)(void))completion;
- (void)pauseAnimating;
- (void)resumeAnimating;
- (void)updateWithSelectedMusic:(AWEMusicSelectItem *)item timePassed:(NSTimeInterval)timePassed;
- (void)resetWithNewStartIndex:(NSInteger)idx;

@end
