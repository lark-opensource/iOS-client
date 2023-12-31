//
//  CJPayAlertController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWindow : UIWindow

@end


@interface CJPayAlertController : UIAlertController

- (void)applyBindCardMessageStyleWithMessage:(NSString *)msg;

- (void)showUse:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
