//
//  CJPayDouyinLoadingView.h
//  Pods
//
//  Created by 易培淮 on 2021/6/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDouyinLoadingView : UIView

+ (CJPayDouyinLoadingView *)showWindowLoadingWithTitle:(nullable NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view
                                    title:(NSString *)title
                                 animated:(BOOL)animated
                               afterDelay:(NSTimeInterval)delay;

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view
                                   title:(NSString *)title
                                    icon:(NSString *)iconName
                                 animated:(BOOL)animated
                                afterDelay:(NSTimeInterval)delay;

+ (CJPayDouyinLoadingView *)showLoadingOnView:(UIView *)view
                                   title:(NSString *)title
                                subTitle:(NSString *)subTitle
                                    icon:(NSString *)iconName
                                 animated:(BOOL)animated
                                   afterDelay:(NSTimeInterval)delay;

+ (CJPayDouyinLoadingView *)showLoadingWithView:(UIView *)showView
                                     onView:(UIView *)view;

+ (CJPayDouyinLoadingView *)showMessageWithTitle:(NSString *)title
                                   subTitle:(NSString *)subTitle;

+ (void)dismissWithAnimated:(BOOL)animated;

- (void)setTitle:(nullable NSString *)title;

- (void)allowUserInteraction:(BOOL)allow;
- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
