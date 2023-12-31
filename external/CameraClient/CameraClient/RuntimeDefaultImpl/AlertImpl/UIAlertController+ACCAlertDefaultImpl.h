//
//  UIAlertController+ACCAlertDefaultImpl.h
//  CameraClient
//
//  Created by haoyipeng on 2021/11/16.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (ACCAlertDefaultImpl)

- (void)acc_show;
- (void)acc_show:(BOOL)animated;
- (void)acc_showFromView:(UIView * _Nullable)view;
- (UILabel * _Nullable)acc_titleLabel;
- (UILabel * _Nullable)acc_messageLabel;

@end
