//
//  UIAlertView+SGMSafeGuard.h
//  SecGuard
//
//  Created by jianghaowne on 2018/5/17.
//

#import <UIKit/UIKit.h>

typedef void (^SGMAlertViewDismissBlock)(NSInteger buttonIndex);
typedef void (^SGMAlertViewCancelBlock)();

@interface UIAlertView (SGMSafeGuard) <UIAlertViewDelegate>

+ (UIAlertView *)sgm_showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                      otherButtonTitles:(NSArray *)titleArray
                              dismissed:(SGMAlertViewDismissBlock)dismissBlock
                               canceled:(SGMAlertViewCancelBlock)cancelBlock;

+ (UIAlertView *)sgm_showAlertViewWithTitle:(NSString *)message;

@end
