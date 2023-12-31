//
//  CAKTextLoadingView.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import <UIKit/UIKit.h>
#import "CAKLoadingProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAKTextLoadingView : UIView <CAKLoadingProtocol, CAKTextLoadingViewProtocol>

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view title:(nullable NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view title:(nullable NSString *)title animated:(BOOL)animated;

+ (CAKTextLoadingView *)showLoadingOnView:(UIView *)view withTitle:(nullable NSString *)title;

- (void)dismiss;

- (void)dismissWithAnimated:(BOOL)animated;

- (void)setTitle:(nullable NSString *)title;

- (void)startAnimating;

- (void)stopAnimating;

- (void)allowUserInteraction:(BOOL)allow;

@end

NS_ASSUME_NONNULL_END
