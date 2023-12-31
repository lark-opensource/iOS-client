//
//  CJPayHalfVerifyPasswordNormalViewController.h
//  Pods
//
//  Created by chenbocheng on 2022/3/30.
//

#import "CJPayHalfVerifyPasswordBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHalfVerifyPasswordNormalViewController : CJPayHalfVerifyPasswordBaseViewController

@property (nonatomic, assign) BOOL isForceNormal;

- (void)showPasswordVerifyKeyboard;

@end

NS_ASSUME_NONNULL_END
