//
//  CJPayDouyinOpenDeskLoadingView.h
//  CJPay-Pods-AwemeCore
//
//  Created by 利国卿 on 2022/6/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDouyinOpenDeskLoadingView : UIView

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view;

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view animated:(BOOL)animated;

+ (CJPayDouyinOpenDeskLoadingView *)showLoadingOnView:(UIView *)view
                                         icon:(NSString *)iconName
                                     animated:(BOOL)animated;

+ (void)dismissWithAnimated:(BOOL)animated;

- (void)allowUserInteraction:(BOOL)allow;
- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
