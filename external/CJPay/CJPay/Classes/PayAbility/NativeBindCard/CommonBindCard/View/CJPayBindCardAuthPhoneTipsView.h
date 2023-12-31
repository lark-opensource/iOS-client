//
//  CJPayBindCardAuthPhoneTipsView.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardAuthPhoneTipsView : UIView

@property (nonatomic, copy) void(^clickCloseButtonBlock)(void);
@property (nonatomic, copy) void(^clickAuthButtonBlock)(void);

- (void)updatePhoneNumber:(NSString *)phoneNumber;

@end

NS_ASSUME_NONNULL_END
