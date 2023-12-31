//
//  UIView+ACCTextLoadingView.h
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/9/7.
//

#import <UIKit/UIKit.h>

@interface UIView (ACCTextLoadingView)

- (void)acc_storeLoadingView:(nullable UIView *)view;

- (BOOL)acc_loadingViewExists;

- (BOOL)acc_loadingViewExistsInHierarchy;

@end
