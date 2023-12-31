//
//  AWETitleRollingTextView.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/4.
//

#import <UIKit/UIKit.h>

@interface AWETitleRollingTextView : UIView

- (void)configureWithRollingText:(NSString *)text
                            font:(UIFont *)font
                       textColor:(UIColor *)textColor
                      labelSpace:(CGFloat)labelSpace
                   numberOfRolls:(NSInteger)numberOfRolls;

- (void)startAnimatingWithDuration:(NSTimeInterval)duration
                          fromView:(UIView *)sourceView;
- (void)stopAnimatingWithCompletion:(void (^)(void))completion;
- (void)pauseAnimating;
- (void)resumeAnimating;

@end
